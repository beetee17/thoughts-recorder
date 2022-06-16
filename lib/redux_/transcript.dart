import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/redux_/recorder.dart';
import 'package:Minutes/redux_/transcriber.dart';
import 'package:Minutes/screens/punctuated_text_screen.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/global_variables.dart';
import 'package:flutter/services.dart';

import 'package:redux/redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../utils/pair.dart';
import '../utils/save_file_contents.dart';
import '../utils/transcript_pair.dart';
import 'audio.dart';

class TranscriptState {
  final List<TranscriptPair> transcriptTextList;
  final List<PunctuatedWord?> punctuatorResult;
  final String highlightedParent;

  String get transcriptText =>
      transcriptTextList.map((pair) => pair.word).join(' ');

  TranscriptState(
      {required this.punctuatorResult,
      required this.highlightedParent,
      required this.transcriptTextList});

  static TranscriptState empty() {
    return TranscriptState(
      highlightedParent: '',
      transcriptTextList: [],
      punctuatorResult: [null],
    );
  }

  TranscriptState copyWith({
    List<TranscriptPair>? transcriptTextList,
    String? highlightedParent,
    List<PunctuatedWord?>? punctuatorResult,
  }) {
    return TranscriptState(
      transcriptTextList: transcriptTextList ?? this.transcriptTextList,
      highlightedParent: highlightedParent ?? this.highlightedParent,
      punctuatorResult: punctuatorResult ?? this.punctuatorResult,
    );
  }

  @override
  String toString() {
    return '\nhighlightedIndex:$highlightedParent'
        '\nTranscript: $transcriptTextList'
        '\nPunctuated: $punctuatorResult';
  }

  @override
  bool operator ==(other) {
    return (other is TranscriptState) &&
        (transcriptTextList == other.transcriptTextList) &&
        (highlightedParent == other.highlightedParent) &&
        (punctuatorResult == other.punctuatorResult);
  }

  @override
  int get hashCode {
    return Object.hash(highlightedParent, transcriptTextList, punctuatorResult);
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

ThunkAction<AppState> Function(PunctuatedWord?, int)
    acceptPunctuatorSuggestion = (PunctuatedWord? suggestion, int wordIndex) {
  return (Store<AppState> store) async {
    if (suggestion == null) {
      return;
    }
    // be careful here with word index
    await store.dispatch(EditWordAction(suggestion.content, wordIndex));
    List<PunctuatedWord?> newPunctuatorResult =
        store.state.transcript.punctuatorResult;
    newPunctuatorResult[wordIndex] = null;

    await store.dispatch(UpdatePunctuatorResult(newPunctuatorResult));
  };
};

ThunkAction<AppState> Function(int) rejectPunctuatorSuggestion =
    (int wordIndex) {
  return (Store<AppState> store) async {
    List<PunctuatedWord?> newPunctuatorResult =
        store.state.transcript.punctuatorResult;

    newPunctuatorResult[wordIndex] = null;

    await store.dispatch(UpdatePunctuatorResult(newPunctuatorResult));
  };
};

class UpdatePunctuatorResult {
  List<PunctuatedWord?> result;
  UpdatePunctuatorResult(this.result);
}

class PunctuateTranscript implements CallableThunkAction<AppState> {
  static const platform = MethodChannel('minutes/punctuator');

  Future<void> _punctuate(Store<AppState> store, String text) async {
    try {
      final arguments = {'text': text};
      final Map? result =
          await platform.invokeMapMethod('punctuateText', arguments);
      if (result != null) {
        await store
            .dispatch(UpdatePunctuatorResult(formatPunctuatorResult(result)));
      }
    } on PlatformException catch (e) {
      print(e);
    }
  }

  List<PunctuatedWord?> formatPunctuatorResult(Map result) {
    final words = (result['words'] as List)
        .map((word) => word as String?)
        .whereType<String>()
        .toList();

    final allScores = (result['scores'] as List)
        .map((punctuationScores) => (punctuationScores as List)
            .map((score) => score as double?)
            .whereType<double>()
            .toList())
        .toList();

    print(allScores);

    final mask = (result['mask'] as List)
        .map((item) => item as bool?)
        .whereType<bool>()
        .toList();

    List<PunctuatedWord?> punctuatedWords = [];
    int wordPos = 0;

    allScores.asMap().forEach((index, punctuationScores) {
      if (index < mask.length && mask[index]) {
        String word = words[wordPos];

        final Pair<int, double> punctuationResult =
            Math.argmax(punctuationScores);
        if (punctuationResult.first > 1 && wordPos + 1 < words.length) {
          // Capitalise the next word if the previous punctuation is not a comma
          words[wordPos + 1] = words[wordPos + 1].toCapitalized();
        }

        if (wordPos == 0) {
          // Capitalise the first word
          word = word.toCapitalized();
        }

        final punctuatedWord = PunctuatedWord(
            word + punctuationMap[punctuationResult.first]!,
            punctuationResult.first,
            punctuationResult.second);
        punctuatedWords.add(punctuatedWord);

        print('${punctuatedWord.content} ${punctuatedWord.confidence}');

        wordPos += 1;
      }
    });

    return punctuatedWords;
  }

  @override
  Future<void> call(Store<AppState> store) async {
    _punctuate(store, store.state.transcript.transcriptText);
  }
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
  } else if (action is UpdatePunctuatorResult) {
    return prevState.copyWith(punctuatorResult: action.result);
  } else {
    return prevState;
  }
}
