import 'dart:io';

import 'package:Minutes/redux_/cheetah.dart';
import 'package:cheetah_flutter/cheetah.dart';
import 'package:file_picker/file_picker.dart';
import 'package:Minutes/mic_recorder.dart';
import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/redux_/recorder.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/redux_/status.dart';
import 'package:Minutes/redux_/transcript.dart';
import 'package:Minutes/redux_/transcriber.dart';
import 'package:Minutes/utils/extensions.dart';
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

  // File Picker Functions
  void pickFile({bool fromGallery = false}) {
    // From SDK Documentation:
    // The file needs to have a sample rate equal to or greater than Leopard.sampleRate.
    // The supported formats are: FLAC, MP3, Ogg, Opus, Vorbis, WAV, and WebM.
    // TODO: Now support any media file type through conversion of file via ffmpeg.
    FilePicker.platform
        .pickFiles(
            type: fromGallery ? FileType.video : FileType.custom,
            allowedExtensions: fromGallery
                ? null
                : [
                    'flac',
                    'mp3',
                    'ogg',
                    'opus',
                    'vorbis',
                    'wav',
                    'webm',
                    'mp4',
                    'mov',
                    'avi'
                  ])
        .then((res) {
      if (res != null) {
        store.dispatch(AudioFileChangeAction(File(res.files.single.path!)));
        print(res.files.single.path!);
        store.dispatch(processCurrentAudioFile);
      } else {
        // User canceled the picker
      }
    });
  }

  void removeSelectedFile() {
    store.dispatch(AudioFileChangeAction(null));
  }
}

class AudioPositionChangeAction {
  Duration newPosition;
  AudioPositionChangeAction(this.newPosition);
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
  final TranscriberState state = store.state.transcriber;
  final AudioState audio = store.state.audio;
  final LeopardState leopard = store.state.leopard;
  final CheetahState cheetah = store.state.cheetah;

  if (leopard.instance == null ||
      audio.file == null ||
      cheetah.instance == null) {
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
    CheetahTranscript cheetahTranscript =
        await cheetah.instance!.process(frame);

    final Duration transcribedLength = Duration(
        milliseconds:
            (data.length / leopard.instance!.sampleRate * 1000).toInt());

    await store.dispatch(getRecordedCallback(
        transcribedLength, frame, cheetahTranscript.isEndpoint));
    await store.dispatch(StatusTextChangeAction(
        "Transcribed ${(transcribedLength.inMilliseconds / 1000).toStringAsFixed(1)} seconds..."));
  }

  await store.dispatch(processRemainingFrames);
};

// Each reducer will handle actions related to the State Tree it cares about!
AudioState audioReducer(AudioState prevState, action) {
  if (action is AudioFileChangeAction) {
    return prevState.copyWith(file: action.file, shouldOverrideFile: true);
  } else if (action is RecordedCallbackUpdateAction) {
    return prevState.copyWith(duration: action.recordedLength);
  } else if (action is CancelRecordSuccessAction) {
    return prevState.copyWith(duration: Duration.zero);
  } else if (action is AudioDurationChangeAction) {
    return prevState.copyWith(duration: action.newDuration);
  } else {
    return prevState;
  }
}
