import 'package:Minutes/redux_/recorder.dart';
import 'package:Minutes/redux_/transcript.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/persistence.dart';
import 'package:flutter/services.dart';
import 'package:leopard_flutter/leopard.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';

import '../ffi.dart';
import 'audio.dart';
import 'rootStore.dart';

// Define your State
class TranscriberState {
  final AutoCorrectSuggestions suggestions;
  final List<int> combinedFrame;
  final Duration combinedDuration;

  TranscriberState(
      {required this.suggestions,
      required this.combinedFrame,
      required this.combinedDuration});

  static TranscriberState empty() {
    return TranscriberState(
        suggestions: AutoCorrectSuggestions.empty(),
        combinedDuration: Duration.zero,
        combinedFrame: []);
  }

  TranscriberState copyWith(
      {AutoCorrectSuggestions? suggestions,
      List<int>? combinedFrame,
      Duration? combinedDuration}) {
    return TranscriberState(
      suggestions: suggestions ?? this.suggestions,
      combinedFrame: combinedFrame ?? this.combinedFrame,
      combinedDuration: combinedDuration ?? this.combinedDuration,
    );
  }

  @override
  String toString() {
    return '\ncombinedDuration: $combinedDuration'
        '\ncombinedFrames: ${combinedFrame.length} frames'
        '\nsuggestions: $suggestions';
  }

  @override
  bool operator ==(other) {
    return (other is TranscriberState) &&
        (combinedFrame == other.combinedFrame) &&
        (suggestions == other.suggestions) &&
        (combinedDuration == other.combinedDuration);
  }

  @override
  int get hashCode {
    return Object.hash(combinedDuration, combinedFrame, suggestions);
  }
}

ThunkAction<AppState> initialiseAutoCorrectSuggestions =
    (Store<AppState> store) async {
  AutoCorrectSuggestions suggestions =
      await Settings.getAutoCorrectSuggestionsMap();
  await store.dispatch(AutoCorrectSuggestionsDidChangeAction(suggestions));
};

ThunkAction<AppState> Function(AutoCorrectSuggestions)
    modifyAutoCorrectSuggestions = (AutoCorrectSuggestions newSuggestions) {
  return (Store<AppState> store) async {
    print("MODIFY");
    final result = await Settings.setAutoCorrectSuggestionsMap(newSuggestions);
    print("SAVED SUCCESSFULLY $result");
    await store.dispatch(AutoCorrectSuggestionsDidChangeAction(newSuggestions));
  };
};

class AutoCorrectTranscript implements CallableThunkAction<AppState> {
  static const platform = MethodChannel('minutes/punctuator');
  final String text;

  AutoCorrectTranscript(this.text);

  Future<void> _autoCorrect(Store<AppState> store, String text) async {
    try {
      text = text.toLowerCase().trim().replaceAll('’', "'");
      print("FORMATTED TEXT $text");

      final AutoCorrectSuggestions suggestions =
          store.state.transcriber.suggestions;
      final String? phraseToCheck = suggestions.checkText(text);
      if (phraseToCheck == null) {
        return;
      }

      text = text.replaceFirst(phraseToCheck, "[MASK]");
      print("MASKED PHRASE TO: $text");
      final List<String> targets = suggestions.getTargets(phraseToCheck);
      targets.add(phraseToCheck);

      final String modelPath = await Leopard.tryExtractFlutterAsset(
          'assets/tokenizer/albert-base-v2-spiece.model');

      print('LOADED MODEL FROM ASSETS SUCCESS: $modelPath');

      final tokens =
          (await api.tokenize(text: text, modelPath: modelPath)).toList();
      print('GOT TOKENS FROM RUST: \n$tokens');

      List<int> targetIds = [];
      targets.add(phraseToCheck.split(' ').join(''));
      Future.forEach(targets, (target) async {
        final ids =
            await api.tokenizeWord(word: "▁$target", modelPath: modelPath);

        print("GOT ID FOR TARGET $target: $ids");
        if (ids.length == 1) {
          return Future(() => targetIds.add(ids[0]));
        }
      }).then((_) {
        print('GOT TARGETS FROM RUST: \n$targetIds');
        final arguments = {'tokens': tokens, 'targets': targetIds};
        platform
            .invokeMapMethod('autoCorrectText', arguments)
            .then((result) => print(result));
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  @override
  call(Store<AppState> store) {
    _autoCorrect(store, text);
  }
}

class AutoCorrectSuggestionsDidChangeAction {
  final AutoCorrectSuggestions newSuggestions;
  AutoCorrectSuggestionsDidChangeAction(this.newSuggestions);
}

// Define your Actions
class StartProcessingAudioFileAction {}

// Each reducer will handle actions related to the State Tree it cares about!
TranscriberState transcriberReducer(TranscriberState prevState, action) {
  // if (action is! AudioPositionChangeAction) {
  //   print(action);
  // }
  if (action is StartRecordSuccessAction) {
    return prevState
        .copyWith(combinedFrame: [], combinedDuration: Duration.zero);
  } else if (action is StartProcessingAudioFileAction) {
    return prevState
        .copyWith(combinedFrame: [], combinedDuration: Duration.zero);
  } else if (action is CancelRecordSuccessAction) {
    return prevState
        .copyWith(combinedFrame: [], combinedDuration: Duration.zero);
  } else if (action is RecordedCallbackUpdateAction) {
    return prevState.copyWith(
        combinedFrame: action.combinedFrame,
        combinedDuration: action.combinedDuration);
  } else if (action is AutoCorrectSuggestionsDidChangeAction) {
    return prevState.copyWith(suggestions: action.newSuggestions);
  } else {
    return prevState;
  }
}
