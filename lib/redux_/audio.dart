import 'dart:io';

import 'package:leopard_demo/mic_recorder.dart';
import 'package:leopard_demo/redux_/recorder.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/redux_/status.dart';
import 'package:leopard_demo/redux_/untitled.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';

class AudioState {
  final File? file;

  final Duration duration;
  AudioState({required this.file, required this.duration});

  static AudioState empty() {
    return AudioState(file: null, duration: Duration.zero);
  }

  AudioState copyWith({
    Duration? duration,
    File? file,
    bool shouldOverrideFile = false,
  }) {
    return AudioState(
        duration: duration ?? this.duration,
        file: shouldOverrideFile ? file : this.file);
  }

  @override
  String toString() {
    return 'file: $file \naudio duration: $duration';
  }

  @override
  bool operator ==(other) {
    return (other is AudioState) &&
        (duration == other.duration) &&
        (file == other.file);
  }

  @override
  int get hashCode {
    return Object.hash(file, duration);
  }
}

class AudioDurationChangeAction {
  Duration newDuration;
  AudioDurationChangeAction(this.newDuration);
}

class AudioFileChangeAction {
  File? file;
  AudioFileChangeAction(this.file);
}

ThunkAction<AppState> processCurrentAudioFile = (Store<AppState> store) async {
  final UntitledState state = store.state.untitled;
  final AudioState audio = store.state.audio;
  if (state.leopard == null || audio.file == null) {
    return;
  }

  store.dispatch(StartProcessingAudioFileAction());

  List<int>? frames = await MicRecorder.getFramesFromFile(audio.file!);
  if (frames == null) {
    print('Did not get any frames from audio file');
    return;
  }

  List<List<int>> allFrames = frames.split(12000);
  List<int> data = [];

  for (final frame in allFrames) {
    data.addAll(frame);
    final Duration transcribedLength = Duration(
        milliseconds: (data.length / state.leopard!.sampleRate * 1000).toInt());
    await store.dispatch(getRecordedCallback(transcribedLength, frame));
    await store.dispatch(StatusTextChangeAction(
        "Transcribed ${(transcribedLength.inMilliseconds / 1000).toStringAsFixed(1)} seconds..."));
  }

  await store.dispatch(processRemainingFrames);
};

// Each reducer will handle actions related to the State Tree it cares about!
AudioState audioReducer(AudioState prevState, action) {
  if (action is! AudioPositionChangeAction) {
    print(action);
  }
  if (action is AudioFileChangeAction) {
    return prevState.copyWith(file: action.file, shouldOverrideFile: true);
  } else if (action is RecordedCallbackUpdateAction) {
    return prevState.copyWith(duration: action.recordedLength);
  } else if (action is AudioDurationChangeAction) {
    return prevState.copyWith(duration: action.newDuration);
  } else {
    return prevState;
  }
}
