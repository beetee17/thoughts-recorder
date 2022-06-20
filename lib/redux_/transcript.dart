import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/redux_/recorder.dart';
import 'package:Minutes/redux_/transcriber.dart';
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
    return Object.hash(highlightedParent, transcriptTextList);
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

ThunkAction<AppState> Function(int) acceptPunctuatorSuggestion =
    (int wordIndex) {
  return (Store<AppState> store) async {
    final TranscriptState state = store.state.transcript;
    final TranscriptPair pair = state.transcriptTextList[wordIndex];
    final newList = state.transcriptTextList;

    newList[wordIndex] = pair
        .mapWord((_) => pair.punctuated)
        .copyWith(punctuationData: null, shouldOverrideData: true);

    await store.dispatch(SetTranscriptListAction(newList));
  };
};

ThunkAction<AppState> Function(int) rejectPunctuatorSuggestion =
    (int wordIndex) {
  return (Store<AppState> store) async {
    final TranscriptState state = store.state.transcript;
    final TranscriptPair pair = state.transcriptTextList[wordIndex];
    final newList = state.transcriptTextList;

    newList[wordIndex] =
        pair.copyWith(punctuationData: null, shouldOverrideData: true);

    await store.dispatch(SetTranscriptListAction(newList));
  };
};

class PunctuateTranscript implements CallableThunkAction<AppState> {
  static const platform = MethodChannel('minutes/punctuator');

  Future<void> _punctuate(Store<AppState> store, String text,
      List<TranscriptPair> transcriptTextList) async {
    try {
      final arguments = {'text': text};
      final Map? result =
          await platform.invokeMapMethod('punctuateText', arguments);
      if (result != null) {
        await store.dispatch(SetTranscriptListAction(
            formatPunctuatorResult(result, transcriptTextList)));
      }
    } on PlatformException catch (e) {
      print(e);
    }
  }

  List<TranscriptPair> formatPunctuatorResult(
      Map result, List<TranscriptPair> transcriptTextList) {
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

    final mask = (result['mask'] as List)
        .map((item) => item as bool?)
        .whereType<bool>()
        .toList();

    List<TranscriptPair> punctuatedWords = [];
    int wordPos = 0;
    print('${words.length}, ${allScores.length}, ${mask.length}');
    print('words: $words');
    int index = 0;
    print(mask);
    for (TranscriptPair pair in transcriptTextList) {
      while (index < allScores.length && !mask[index]) {
        index++;
      }
      if (index < allScores.length) {
        String word = words[wordPos].toLowerCase().trim();
        // We want our words formatted in the same way as how it was returned by AlbertPunctuator so semantic equality can be checked
        // TODO: Need to take care of case where word is in single quotes e.g. 'hello'
        String originalWord = pair.word
            .toLowerCase()
            .trim()
            .replaceAll('’', "'")
            .split(punctuationCharacters)
            .join('');
        print('${word} | origin: ${originalWord} | index: $index');
        if (originalWord != word) {
          print('DIFF');
          // Just copy over
          punctuatedWords.add(pair);
        } else {
          final List<double> punctuationScores = allScores[index];
          final Pair<int, double> punctuationResult =
              Math.argmax(punctuationScores);
          // If suggestion is no punctuation, we only add if the origianly word was capitalised
          // i.e. The suggestion is to remove capitalisation
          punctuatedWords.add(pair.copyWith(
              punctuationData: (punctuationResult.first > 0 ||
                      (pair.word.isNotEmpty &&
                          pair.word.trim().isCapitalised()))
                  ? punctuationResult
                  : null,
              shouldOverrideData: true));
          wordPos += 1;
          index++;
        }
      }
    }

    return punctuatedWords;
  }

  @override
  Future<void> call(Store<AppState> store) async {
    _punctuate(store, store.state.transcript.transcriptText,
        store.state.transcript.transcriptTextList);
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

    newList[action.wordIndex] = prevPair.mapWord((word) => word + action.text);
    return prevState.copyWith(transcriptTextList: newList);
  } else if (action is DeleteWordAction) {
    final newList = prevState.transcriptTextList;
    newList.removeAt(action.wordIndex);
    return prevState.copyWith(transcriptTextList: newList);
  } else if (action is EditWordAction) {
    final TranscriptPair prevPair =
        prevState.transcriptTextList[action.wordIndex];
    final newList = prevState.transcriptTextList;

    newList[action.wordIndex] = prevPair.mapWord((word) => action.newWord);
    return prevState.copyWith(transcriptTextList: newList);
  } else {
    return prevState;
  }
}
