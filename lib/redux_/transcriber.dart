import 'package:Minutes/redux_/recorder.dart';
import 'package:Minutes/redux_/transcript.dart';

import 'audio.dart';

// Define your State
class TranscriberState {
  final List<int> combinedFrame;
  final Duration combinedDuration;

  TranscriberState(
      {required this.combinedFrame, required this.combinedDuration});

  static TranscriberState empty() {
    return TranscriberState(combinedDuration: Duration.zero, combinedFrame: []);
  }

  TranscriberState copyWith(
      {List<int>? combinedFrame, Duration? combinedDuration}) {
    return TranscriberState(
      combinedFrame: combinedFrame ?? this.combinedFrame,
      combinedDuration: combinedDuration ?? this.combinedDuration,
    );
  }

  @override
  String toString() {
    return '\ncombinedDuration: $combinedDuration'
        '\ncombinedFrames: ${combinedFrame.length} frames';
  }

  @override
  bool operator ==(other) {
    return (other is TranscriberState) &&
        (combinedFrame == other.combinedFrame) &&
        (combinedDuration == other.combinedDuration);
  }

  @override
  int get hashCode {
    return Object.hash(combinedDuration, combinedFrame);
  }
}

// Define your Actions
class StartProcessingAudioFileAction {}

// Each reducer will handle actions related to the State Tree it cares about!
TranscriberState transcriberReducer(TranscriberState prevState, action) {
  if (action is! AudioPositionChangeAction) {
    print(action);
  }
  if (action is StartRecordSuccessAction) {
    return prevState
        .copyWith(combinedFrame: [], combinedDuration: Duration.zero);
  } else if (action is StartProcessingAudioFileAction) {
    return prevState
        .copyWith(combinedFrame: [], combinedDuration: Duration.zero);
  } else if (action is IncomingTranscriptAction) {
    return prevState
        .copyWith(combinedFrame: [], combinedDuration: Duration.zero);
  } else if (action is RecordedCallbackUpdateAction) {
    return prevState.copyWith(
        combinedFrame: action.combinedFrame,
        combinedDuration: action.combinedDuration);
  } else {
    return prevState;
  }
}
