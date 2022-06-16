import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/redux_/recorder.dart';
import 'package:Minutes/redux_/transcriber.dart';
import 'package:Minutes/utils/extensions.dart';

import 'package:redux/redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../utils/save_file_contents.dart';
import '../utils/transcript_pair.dart';
import 'audio.dart';

class TranscriptState {
  final List<TranscriptPair> transcriptTextList;
  final String highlightedParent;

  String get transcriptText =>
      transcriptTextList.map((pair) => pair.word).join(' ');

  TranscriptState(
      {required this.highlightedParent, required this.transcriptTextList});

  static TranscriptState empty() {
    return TranscriptState(
      highlightedParent: '',
      transcriptTextList: [],
    );
  }

  TranscriptState copyWith({
    List<TranscriptPair>? transcriptTextList,
    String? highlightedParent,
  }) {
    return TranscriptState(
      transcriptTextList: transcriptTextList ?? this.transcriptTextList,
      highlightedParent: highlightedParent ?? this.highlightedParent,
    );
  }

  @override
  String toString() {
    return '\nhighlightedIndex:$highlightedParent'
        '\nTranscript: $transcriptTextList';
  }

  @override
  bool operator ==(other) {
    return (other is TranscriptState) &&
        (transcriptTextList == other.transcriptTextList) &&
        (highlightedParent == other.highlightedParent);
  }

  @override
  int get hashCode {
    return Object.hash(
      highlightedParent,
      transcriptTextList,
    );
  }

  void highlightSpan(String parent) {
    store.dispatch(HighlightWordsWithParent(parent));
  }
}

class ClearAllAction {}

class HighlightWordsWithParent {
  String parent;
  HighlightWordsWithParent(this.parent);
}

class IncomingTranscriptAction {
  // A list of words of the transcript
  List<TranscriptPair> transcript;
  IncomingTranscriptAction(this.transcript);
}

class UpdateTranscriptTextList {
  String editedParent;
  String editedContents;
  UpdateTranscriptTextList(this.editedParent, this.editedContents);
}

class ProcessedRemainingFramesAction {
  List<TranscriptPair> remainingTranscript;
  ProcessedRemainingFramesAction(this.remainingTranscript);
}

class SetTranscriptListAction {
  List<TranscriptPair> transcriptList;
  SetTranscriptListAction(this.transcriptList);
}

class AddTextAfterWordAction {
  String text;
  int wordIndex;
  AddTextAfterWordAction(this.text, this.wordIndex);
}

class DeleteWordAction {
  int wordIndex;
  DeleteWordAction(this.wordIndex);
}

class EditWordAction {
  String newWord;
  int wordIndex;
  EditWordAction(this.newWord, this.wordIndex);
}

ThunkAction<AppState> Function(SaveFileContents) loadTranscript =
    (SaveFileContents transcript) {
  return (Store<AppState> store) async {
    await store.dispatch(SetTranscriptListAction(transcript.transcript));
    await store.dispatch(AudioFileChangeAction(transcript.audio));
  };
};

ThunkAction<AppState> processRemainingFrames = (Store<AppState> store) async {
  TranscriberState state = store.state.transcriber;
  LeopardState leopard = store.state.leopard;
  AudioState audio = store.state.audio;

  final remainingFrames = state.combinedFrame;

  final Duration startTime =
      DurationUtils.max(Duration.zero, audio.duration - state.combinedDuration);
  final List<TranscriptPair>? remainingTranscript =
      await leopard.processCombined(remainingFrames, startTime);
  if (remainingTranscript?.isNotEmpty ?? false) {
    await store.dispatch(ProcessedRemainingFramesAction(remainingTranscript!));
  }
  await store.dispatch(AudioFileChangeAction(audio.file));
};

// Each reducer will handle actions related to the State Tree it cares about!
TranscriptState transcriptReducer(TranscriptState prevState, action) {
  if (action is HighlightWordsWithParent) {
    return prevState.copyWith(highlightedParent: action.parent);
  } else if (action is StartRecordSuccessAction) {
    return TranscriptState.empty();
  } else if (action is CancelRecordSuccessAction) {
    return TranscriptState.empty();
  } else if (action is ProcessedRemainingFramesAction) {
    final newTranscriptTextList = prevState.transcriptTextList;
    newTranscriptTextList.addAll(action.remainingTranscript);
    return prevState.copyWith(
        transcriptTextList: newTranscriptTextList,
        highlightedParent: newTranscriptTextList.first.parent);
  } else if (action is StartProcessingAudioFileAction) {
    return prevState.copyWith(transcriptTextList: [], highlightedParent: null);
  } else if (action is UpdateTranscriptTextList) {
    return prevState.copyWith(
        transcriptTextList: prevState.transcriptTextList
            .edit(action.editedContents, action.editedParent));
  } else if (action is SetTranscriptListAction) {
    return prevState.copyWith(transcriptTextList: action.transcriptList);
  } else if (action is IncomingTranscriptAction) {
    final newTranscriptTextList = prevState.transcriptTextList;
    newTranscriptTextList.addAll(action.transcript);
    return prevState.copyWith(
        transcriptTextList: newTranscriptTextList,
        highlightedParent: newTranscriptTextList.last.parent);
  } else if (action is AudioPositionChangeAction) {
    final int highlightIndex = prevState.transcriptTextList.lastIndexWhere(
        // We do not want the edge cases due to rounding errors
        (pair) => pair.startTime <= action.newPosition);
    return prevState.copyWith(
        highlightedParent: prevState.transcriptTextList[highlightIndex].parent);
  } else if (action is AddTextAfterWordAction) {
    final TranscriptPair prevPair =
        prevState.transcriptTextList[action.wordIndex];
    final newList = prevState.transcriptTextList;

    newList[action.wordIndex] = prevPair.copyWith((word) => word + action.text);
    return prevState.copyWith(transcriptTextList: newList);
  } else if (action is DeleteWordAction) {
    final newList = prevState.transcriptTextList;
    newList.removeAt(action.wordIndex);
    return prevState.copyWith(transcriptTextList: newList);
  } else if (action is EditWordAction) {
    final TranscriptPair prevPair =
        prevState.transcriptTextList[action.wordIndex];
    final newList = prevState.transcriptTextList;

    newList[action.wordIndex] = prevPair.copyWith((word) => action.newWord);
    return prevState.copyWith(transcriptTextList: newList);
  } else {
    return prevState;
  }
}
