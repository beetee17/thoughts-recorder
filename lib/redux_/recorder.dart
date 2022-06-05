import 'package:Minutes/mic_recorder.dart';
import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/redux_/transcript.dart';
import 'package:Minutes/redux_/transcriber.dart';

import 'package:leopard_flutter/leopard_error.dart';
import 'package:redux/redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../utils/extensions.dart';
import '../utils/global_variables.dart';
import '../utils/pair.dart';
import 'audio.dart';

class RecorderState {
  final bool isRecording;
  final bool finishedRecording;
  final MicRecorder? micRecorder;
  RecorderState(
      {required this.micRecorder,
      required this.finishedRecording,
      required this.isRecording});
  static RecorderState empty() {
    return RecorderState(
        finishedRecording: true, isRecording: false, micRecorder: null);
  }

  RecorderState copyWith(
      {bool? isRecording, bool? finishedRecording, MicRecorder? micRecorder}) {
    return RecorderState(
      finishedRecording: finishedRecording ?? this.finishedRecording,
      isRecording: isRecording ?? this.isRecording,
      micRecorder: micRecorder ?? this.micRecorder,
    );
  }

  @override
  String toString() {
    return ' \nMicRecorder: $micRecorder ';
  }

  @override
  bool operator ==(other) {
    return (other is RecorderState) &&
        (finishedRecording == other.finishedRecording) &&
        (isRecording == other.isRecording) &&
        (micRecorder == other.micRecorder);
  }

  @override
  int get hashCode {
    return Object.hash(finishedRecording, isRecording, micRecorder);
  }

  // Recorder Functions
  Future<void> startRecording() async {
    if (isRecording || micRecorder == null) {
      return;
    }
    try {
      if (!finishedRecording) {
        await store.dispatch(ResumeRecordSuccessAction());
      } else {
        await micRecorder!.clearData();
        await store.dispatch(StartRecordSuccessAction());
      }
      await micRecorder!.startRecord();
      print('Started recording');
    } on LeopardException catch (ex) {
      print("Failed to start audio capture: ${ex.message}");
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording || micRecorder == null) {
      return;
    }

    try {
      final file = await micRecorder!.stopRecord();
      await store.dispatch(AudioFileChangeAction(file));
      await store.dispatch(processRemainingFrames);
    } on LeopardException catch (ex) {
      print("Failed to stop audio capture: ${ex.message}");
    }
  }

  Future<void> pauseRecording() async {
    if (!isRecording || micRecorder == null) {
      return;
    }

    try {
      await micRecorder!.pauseRecord();
      await store.dispatch(PauseRecordSuccessAction());
    } on LeopardException catch (ex) {
      print("Failed to stop audio capture: ${ex.message}");
    }
  }
}

class StartRecordSuccessAction {}

class PauseRecordSuccessAction {}

class ResumeRecordSuccessAction {}

class RecordedCallbackUpdateAction {
  Duration recordedLength;
  List<int> combinedFrame;
  Duration combinedDuration;
  RecordedCallbackUpdateAction(
      this.recordedLength, this.combinedFrame, this.combinedDuration);
}

ThunkAction<AppState> Function(Duration, List<int>) getRecordedCallback =
    (Duration length, List<int> frame) {
  return (Store<AppState> store) async {
    if (length.inSeconds < maxRecordingLength.inSeconds) {
      TranscriberState state = store.state.transcriber;
      RecorderState recorder = store.state.recorder;
      LeopardState leopard = store.state.leopard;

      String singleFrameTranscript = await leopard.instance!.process(frame);

      List<int> newCombinedFrame = state.combinedFrame;
      newCombinedFrame.addAll(frame);

      Duration newCombinedDuration = state.combinedDuration +
          Duration(
              milliseconds:
                  (frame.length / recorder.micRecorder!.sampleRate * 1000)
                      .toInt());

      if (singleFrameTranscript == null ||
          singleFrameTranscript.trim().isEmpty) {
        print('potential end point, duration: $newCombinedDuration');

        if (newCombinedDuration.inSeconds > 4) {
          final Duration startTime =
              DurationUtils.max(Duration.zero, length - newCombinedDuration);

          // we want the startTime of the text rather than the end
          Pair<String, Duration> incomingTranscript =
              await leopard.processCombined(newCombinedFrame, startTime);
          await store.dispatch(IncomingTranscriptAction(incomingTranscript));
        } else {
          await store.dispatch(RecordedCallbackUpdateAction(
              length, newCombinedFrame, newCombinedDuration));
        }
      } else {
        await store.dispatch(RecordedCallbackUpdateAction(
            length, newCombinedFrame, newCombinedDuration));
      }
    } else {
      await store.state.recorder.stopRecording();
    }
  };
};

// Each reducer will handle actions related to the State Tree it cares about!
RecorderState recorderReducer(RecorderState prevState, action) {
  if (action is! AudioPositionChangeAction) {
    print(action);
  }
  if (action is InitialisationSuccessAction) {
    return prevState.copyWith(micRecorder: action.micRecorder);
  } else if (action is StartRecordSuccessAction) {
    return prevState.copyWith(isRecording: true, finishedRecording: false);
  } else if (action is ResumeRecordSuccessAction) {
    return prevState.copyWith(isRecording: true, finishedRecording: false);
  } else if (action is AudioFileChangeAction) {
    return prevState.copyWith(isRecording: false, finishedRecording: true);
  } else if (action is PauseRecordSuccessAction) {
    return prevState.copyWith(isRecording: false, finishedRecording: false);
  } else if (action is ProcessedRemainingFramesAction) {
    return prevState.copyWith(isRecording: false);
  } else {
    return prevState;
  }
}
