import 'package:leopard_demo/redux_/recorder.dart';
import 'package:leopard_demo/redux_/transcript.dart';

import 'audio.dart';

// Define your State
class UntitledState {
  final List<int> combinedFrame;
  final Duration combinedDuration;

  UntitledState({required this.combinedFrame, required this.combinedDuration});

  static UntitledState empty() {
    return UntitledState(combinedDuration: Duration.zero, combinedFrame: []);
  }

  UntitledState copyWith(
      {List<int>? combinedFrame, Duration? combinedDuration}) {
    return UntitledState(
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
    return (other is UntitledState) &&
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
UntitledState untitledReducer(UntitledState prevState, action) {
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
