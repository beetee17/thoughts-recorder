import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/utils/extensions.dart';

// Define your State
class AudioState {
  final int duration;
  final int currentPos;
  final String currentPosLabel;
  final bool isPlaying;
  final bool finishedPlaying;
  static AudioPlayer player = AudioPlayer();

  @override
  String toString() {
    return 'duration: $duration \ncurrentPos:$currentPos \ncurrentPosLabel:$currentPosLabel \nisPlaying:$isPlaying \nfinishedPlaying:$finishedPlaying';
  }

  @override
  bool operator ==(other) {
    return (other is AudioState) &&
        (duration == other.duration) &&
        (currentPos == other.currentPos) &&
        (currentPosLabel == other.currentPosLabel) &&
        (isPlaying == other.isPlaying) &&
        (finishedPlaying == other.finishedPlaying);
  }

  @override
  int get hashCode {
    return Object.hash(
        duration, currentPos, currentPosLabel, isPlaying, finishedPlaying);
  }

  AudioState({
    required this.duration,
    required this.currentPos,
    required this.currentPosLabel,
    required this.isPlaying,
    required this.finishedPlaying,
  });

  static void initialisePlayer() {
    // INITIALISE AUDIO PLAYER
    player.onDurationChanged.listen((Duration d) {
      seek(0);
      store.dispatch(AudioDurationChangeAction(d));
    });

    player.onAudioPositionChanged.listen((Duration p) {
      store.dispatch(AudioPositionChangeAction(p));
    });

    player.onPlayerStateChanged.listen((event) {
      if (event == PlayerState.COMPLETED) {
        seek(0);
        store.dispatch(AudioPlayerStateCompletedAction());
      }
    });
  }

  // Audio Player Functions
  static seek(double value) async {
    Duration seekVal = Duration(milliseconds: value.round());
    int result = await player.seek(seekVal);
    if (result == 1) {
      // seek successful
      store.dispatch(AudioPositionChangeAction(seekVal));
    } else {
      print("Seek unsuccessful.");
    }
  }

  togglePlayPause(file) async {
    if (!isPlaying && !finishedPlaying) {
      int result = await player.play(file!.path, isLocal: true);
      if (result == 1) {
        store.dispatch(AudioPlaySuccessAction());
      } else {
        print("Error while playing audio.");
      }
    } else if (finishedPlaying && !isPlaying) {
      int result = await player.resume();
      if (result == 1) {
        store.dispatch(AudioResumeSuccessAction());
      } else {
        print("Error on resume audio.");
      }
    } else {
      int result = await player.pause();
      if (result == 1) {
        store.dispatch(AudioPauseSuccessAction());
      } else {
        print("Error on pause audio.");
      }
    }
  }

  static stopPlayer() async {
    int result = await player.stop();
    if (result == 1) {
      store.dispatch(AudioStopSuccessAction());
    } else {
      print("Error on stop audio.");
    }
  }

  static AudioState empty() {
    return AudioState(
        duration: 100,
        currentPos: 0,
        currentPosLabel: '0:00',
        isPlaying: false,
        finishedPlaying: false);
  }

  AudioState copyWith({
    int? duration,
    int? currentPos,
    String? currentPosLabel,
    bool? isPlaying,
    bool? finishedPlaying,
  }) {
    return AudioState(
      duration: duration ?? this.duration,
      currentPos: currentPos ?? this.currentPos,
      currentPosLabel: currentPosLabel ?? this.currentPosLabel,
      isPlaying: isPlaying ?? this.isPlaying,
      finishedPlaying: finishedPlaying ?? this.finishedPlaying,
    );
  }
}

// Define your Actions
class ReleaseAudioFileAction {}

class AudioDurationChangeAction {
  Duration newDuration;
  AudioDurationChangeAction(this.newDuration);
}

class AudioPositionChangeAction {
  Duration newPosition;
  AudioPositionChangeAction(this.newPosition);
}

class AudioPlayerStateCompletedAction {}

class AudioTogglePlayPauseAction {
  File file;
  AudioTogglePlayPauseAction(this.file);
}

class AudioPlaySuccessAction {}

class AudioResumeSuccessAction {}

class AudioPauseSuccessAction {}

class AudioStopSuccessAction {}

// Individual Reducers.
// Each reducer will handle actions related to the State Tree it cares about!
AudioState audioReducer(AudioState prevState, action) {
  if (action is! AudioPositionChangeAction) {
    print(action);
  }
  if (action is AudioDurationChangeAction) {
    return prevState.copyWith(duration: action.newDuration.inMilliseconds);
  } else if (action is AudioPositionChangeAction) {
    return prevState.copyWith(
        currentPos: action.newPosition.inMilliseconds,
        currentPosLabel: action.newPosition.toAudioDurationString());
  } else if (action is AudioPlayerStateCompletedAction) {
    return prevState.copyWith(isPlaying: false);
  } else if (action is AudioPlaySuccessAction) {
    return prevState.copyWith(isPlaying: true, finishedPlaying: false);
  } else if (action is AudioResumeSuccessAction) {
    return prevState.copyWith(isPlaying: true, finishedPlaying: true);
  } else if (action is AudioPauseSuccessAction) {
    return prevState.copyWith(isPlaying: false);
  } else if (action is AudioStopSuccessAction) {
    return prevState.copyWith(
        isPlaying: false, finishedPlaying: false, currentPos: 0);
  } else {
    return prevState;
  }
}
