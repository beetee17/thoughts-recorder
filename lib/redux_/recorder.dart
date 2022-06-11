import 'dart:math';

import 'package:Minutes/mic_recorder.dart';
import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/redux_/transcript.dart';
import 'package:Minutes/redux_/transcriber.dart';
import 'package:cheetah_flutter/cheetah.dart';

import 'package:leopard_flutter/leopard_error.dart';
import 'package:redux/redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../utils/extensions.dart';
import '../utils/global_variables.dart';
import '../utils/transcript_pair.dart';
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

  // Recorder Functions. These can be made into Thunk Actions
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
    if (isRecording || micRecorder == null) {
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

  Future<void> cancelRecording() async {
    if (micRecorder == null) {
      return;
    }

    try {
      await micRecorder!.clearData();
      await micRecorder!.stopRecord();
      await store.dispatch(CancelRecordSuccessAction());
    } catch (err) {
      print("Failed to cancel recording: $err");
    }
  }
}

class CancelRecordSuccessAction {}

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

ThunkAction<AppState> Function(Duration, List<int>, bool) getRecordedCallback =
    (Duration length, List<int> frame, bool isEndpoint) {
  return (Store<AppState> store) async {
    if (length < maxRecordingLength) {
      TranscriberState state = store.state.transcriber;
      RecorderState recorder = store.state.recorder;
      LeopardState leopard = store.state.leopard;

      if (isEndpoint) {
        // Subtract enpointDuration worth of frames from current and put it into next state
        final double secondsPerFrame =
            frame.length / recorder.micRecorder!.sampleRate;
        final numFrames = 0.5 ~/ secondsPerFrame;

        final int numFramesToSubtract = frame.length * numFrames;

        final Duration durationToSubtract = Duration(
            milliseconds:
                (numFramesToSubtract / recorder.micRecorder!.sampleRate * 1000)
                    .toInt());

        final framesToProcess = state.combinedFrame.sublist(
            0, max(0, state.combinedFrame.length - numFramesToSubtract));

        final Duration startTime = DurationUtils.max(Duration.zero,
            length - (state.combinedDuration - durationToSubtract));

        // we want the startTime of the text rather than the end
        TranscriptPair? incomingTranscript =
            await leopard.processCombined(framesToProcess, startTime);

        final leftOverFrames = state.combinedFrame
            .sublist(max(0, state.combinedFrame.length - numFramesToSubtract));

        if (incomingTranscript != null) {
          await store.dispatch(IncomingTranscriptAction(incomingTranscript));
        }

        await store.dispatch(RecordedCallbackUpdateAction(
            length, leftOverFrames, durationToSubtract));
      } else {
        var newCombinedFrame = state.combinedFrame;
        newCombinedFrame.addAll(frame);

        Duration newCombinedDuration = state.combinedDuration +
            Duration(
                milliseconds:
                    (frame.length / recorder.micRecorder!.sampleRate * 1000)
                        .toInt());
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
  } else if (action is CancelRecordSuccessAction) {
    return prevState.copyWith(isRecording: false, finishedRecording: true);
  } else if (action is ProcessedRemainingFramesAction) {
    return prevState.copyWith(isRecording: false);
  } else {
    return prevState;
  }
}
