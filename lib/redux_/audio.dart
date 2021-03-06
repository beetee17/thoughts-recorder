import 'dart:io';

import 'package:Minutes/redux_/cheetah.dart';
import 'package:Minutes/utils/alert_dialog.dart';
import 'package:cheetah_flutter/cheetah.dart';
import 'package:cheetah_flutter/cheetah_error.dart';
import 'package:file_picker/file_picker.dart';
import 'package:Minutes/mic_recorder.dart';
import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/redux_/recorder.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/redux_/status.dart';
import 'package:Minutes/redux_/transcript.dart';
import 'package:Minutes/redux_/transcriber.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:flutter/material.dart';
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
  void pickFile(BuildContext context, {bool fromGallery = false}) {
    // From SDK Documentation:
    // The file needs to have a sample rate equal to or greater than Leopard.sampleRate.
    // The supported formats are: FLAC, MP3, Ogg, Opus, Vorbis, WAV, and WebM.
    // TODO: Now support any media file type through conversion of file via ffmpeg.
    FilePicker.platform
        .pickFiles(
            type: fromGallery ? FileType.video : FileType.any,
            allowedExtensions: null)
        .then((res) {
      if (res != null) {
        // Convert file to wav then get the file path
        final pickedFile = File(res.files.single.path!);
        print('Picked File at Path: ${pickedFile.path}');

        MicRecorder.convertFileToWav(pickedFile).then((wavFile) {
          print('converted picked file to .wav with result: ${wavFile?.path}');
          if (wavFile != null) {
            store.dispatch(AudioFileChangeAction(wavFile));
            store.dispatch(processCurrentAudioFile);
          } else {
            showAlertDialog(context, "Error Converting File",
                "Could not extract audio from the file: ${res.files.single.name}. Please try another file.");
          }
        });
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
  print(cheetah.instance!.frameLength);

  store.dispatch(StartProcessingAudioFileAction());

  List<int>? frames = await MicRecorder.getFramesFromFile(audio.file!);
  if (frames == null) {
    print('Did not get any frames from audio file');
    return;
  }

  List<List<int>> allFrames = frames.split(cheetah.instance!.frameLength);
  List<int> data = [];

  for (final frame in allFrames) {
    data.addAll(frame);

    final Duration transcribedLength = Duration(
        milliseconds:
            (data.length / leopard.instance!.sampleRate * 1000).toInt());
    await store.dispatch(StatusTextChangeAction(
        "Transcribed ${(transcribedLength.inMilliseconds / 1000).toStringAsFixed(1)} seconds..."));
    try {
      CheetahTranscript cheetahTranscript =
          await cheetah.instance!.process(frame);
      if (cheetahTranscript.isEndpoint) {
        CheetahTranscript? ct = await store.state.cheetah.instance?.flush();
        print('Cheetah flushed: (${ct?.transcript.trim()})');
        // Do not know why but it detects endpoint twice in a row
        if (ct?.transcript.trim().isNotEmpty ?? false) {
          await store
              .dispatch(getRecordedCallback(transcribedLength, frame, true));
        }
      } else {
        await store
            .dispatch(getRecordedCallback(transcribedLength, frame, false));
      }
    } on CheetahInvalidArgumentException {
      // Last frame length is likely not exactly what is required
      await store.dispatch(getRecordedCallback(transcribedLength, frame, true));
      break;
    }
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
