import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:leopard_demo/mic_recorder.dart';
import 'package:leopard_demo/redux_/audio.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:leopard_demo/utils/global_variables.dart';
import 'package:leopard_demo/utils/utils.dart';

import 'package:leopard_flutter/leopard.dart';
import 'package:leopard_flutter/leopard_error.dart';

import 'package:redux/redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Define your State
class UntitledState {
  final String? errorMessage;

  final bool isRecording;

  final bool isProcessing;

  final double recordedLength;

  final String statusAreaText;

  final List<int> combinedFrame;
  final double combinedDuration;

  final List<Pair<String, double>> transcriptTextList;
  final int? highlightedSpanIndex;

  String get transcriptText => transcriptTextList.map((p) => p.first).join(' ');

  final MicRecorder? micRecorder;
  final Leopard? leopard;
  final File? file;

  UntitledState(
      {required this.errorMessage,
      required this.highlightedSpanIndex,
      required this.micRecorder,
      required this.leopard,
      required this.file,
      required this.isRecording,
      required this.isProcessing,
      required this.recordedLength,
      required this.statusAreaText,
      required this.combinedFrame,
      required this.combinedDuration,
      required this.transcriptTextList});

  static UntitledState empty() {
    return UntitledState(
      combinedDuration: 0,
      combinedFrame: [],
      errorMessage: null,
      file: null,
      highlightedSpanIndex: null,
      isProcessing: false,
      isRecording: false,
      leopard: null,
      micRecorder: null,
      recordedLength: 0,
      statusAreaText: 'Press START to start recording some audio to transcribe',
      transcriptTextList: [],
    );
  }

  UntitledState copyWith(
      {String? errorMessage,
      bool? isRecording,
      bool? isProcessing,
      double? recordedLength,
      String? statusAreaText,
      List<int>? combinedFrame,
      double? combinedDuration,
      List<Pair<String, double>>? transcriptTextList,
      int? highlightedSpanIndex,
      MicRecorder? micRecorder,
      Leopard? leopard,
      File? file,
      bool shouldOverrideFile = false}) {
    return UntitledState(
      errorMessage: errorMessage ?? this.errorMessage,
      isRecording: isRecording ?? this.isRecording,
      isProcessing: isProcessing ?? this.isProcessing,
      recordedLength: recordedLength ?? this.recordedLength,
      statusAreaText: statusAreaText ?? this.statusAreaText,
      combinedFrame: combinedFrame ?? this.combinedFrame,
      combinedDuration: combinedDuration ?? this.combinedDuration,
      transcriptTextList: transcriptTextList ?? this.transcriptTextList,
      highlightedSpanIndex: highlightedSpanIndex,
      micRecorder: micRecorder ?? this.micRecorder,
      leopard: leopard ?? this.leopard,
      file: shouldOverrideFile ? file : this.file,
    );
  }

  @override
  String toString() {
    return 'file: $file \ncombinedDuration: $combinedDuration \ncombinedFrames: ${combinedFrame.length} items \nMicRecorder: $micRecorder \nTranscript: $transcriptTextList';
  }

  static ThunkAction<AppState> initLeopard = (Store<AppState> store) async {
    if (store.state.untitled.leopard != null &&
        store.state.untitled.micRecorder != null) {
      return;
    }
    String platform = Platform.isAndroid
        ? "android"
        : Platform.isIOS
            ? "ios"
            : throw LeopardRuntimeException(
                "This demo supports iOS and Android only.");
    String modelPath = "assets/models/ios/myModel-leopard.pv";

    try {
      final leopard = await Leopard.create(accessKey, modelPath);
      final micRecorder = await MicRecorder.create(
          leopard.sampleRate, store.state.untitled.errorCallback);
      print('dispatching $leopard and $micRecorder');
      store.dispatch(InitAction(leopard, micRecorder));
    } on LeopardInvalidArgumentException catch (ex) {
      store.state.untitled.errorCallback(LeopardInvalidArgumentException(
          "${ex.message}\nEnsure your accessKey '$accessKey' is a valid access key."));
    } on LeopardActivationException {
      store.state.untitled.errorCallback(
          LeopardActivationException("AccessKey activation error."));
    } on LeopardActivationLimitException {
      store.state.untitled.errorCallback(LeopardActivationLimitException(
          "AccessKey reached its device limit."));
    } on LeopardActivationRefusedException {
      store.state.untitled.errorCallback(
          LeopardActivationRefusedException("AccessKey refused."));
    } on LeopardActivationThrottledException {
      store.state.untitled.errorCallback(
          LeopardActivationThrottledException("AccessKey has been throttled."));
    } on LeopardException catch (ex) {
      store.state.untitled.errorCallback(ex);
    }
  };

  void highlightSpan(int index) {
    store.dispatch(HighlightSpanAtIndex(index));
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
      } else {
        // User canceled the picker
      }
    });
  }

  void removeSelectedFile() {
    store.dispatch(AudioFileChangeAction(null));
    AudioState.stopPlayer();
  }

  // Recorder Functions
  Future<void> startRecording() async {
    if (isRecording || micRecorder == null) {
      return;
    }
    try {
      await micRecorder!.startRecord();
      store.dispatch(StartRecordSuccessAction());
      print('Started recording: $transcriptTextList');
    } on LeopardException catch (ex) {
      print("Failed to start audio capture: ${ex.message}");
    }
  }

  Future<Pair<String, double>> processCombined(
      List<int> combinedFrame, double startTime) async {
    // TODO: Handle if leopard is somehow not initialised.
    final transcript = await leopard!.process(combinedFrame);
    return Pair(
        HighlightableSpanEditor.BEGIN_FLAG +
            transcript.toLowerCase() +
            HighlightableSpanEditor.TERMINATING_FLAG,
        startTime);
  }

  Future<void> stopRecording() async {
    if (!isRecording || micRecorder == null) {
      return;
    }

    try {
      final file = await micRecorder!.stopRecord();
      final remainingFrames = combinedFrame;
      remainingFrames.addAll(micRecorder!.combinedFrame);

      final double startTime = max(0, recordedLength - combinedDuration);
      final remainingTranscript =
          await processCombined(combinedFrame, startTime);

      store.dispatch(StopRecordSucessAction(remainingTranscript));
      AudioState.player.release().then((value) {
        store.dispatch(AudioFileChangeAction(file));
        // AudioState.stopPlayer();
        AudioState.player = AudioPlayer();
        AudioState.initialisePlayer();
      });
    } on LeopardException catch (ex) {
      print("Failed to stop audio capture: ${ex.message}");
    }
  }

  void errorCallback(LeopardException error) {
    store.dispatch(ErrorCallbackAction(error.message ?? error.toString()));
  }
}

// Define your Actions
class InitAction {
  Leopard leopard;
  MicRecorder micRecorder;
  InitAction(this.leopard, this.micRecorder);
}

class HighlightSpanAtIndex {
  int index;
  HighlightSpanAtIndex(this.index);
}

class AudioFileChangeAction {
  File? file;
  AudioFileChangeAction(this.file);
}

class StartRecordSuccessAction {}

class StopRecordSucessAction {
  Pair<String, double> remainingTranscript;
  StopRecordSucessAction(this.remainingTranscript);
}

class StartProcessingAudioFileAction {}

class ProcessAudioFileSuccessAction {
  String statusAreaText;
  List<Pair<String, double>> transcriptTextList;
  ProcessAudioFileSuccessAction(this.statusAreaText, this.transcriptTextList);
}

class ErrorCallbackAction {
  String errorMessage;
  ErrorCallbackAction(this.errorMessage);
}

class RecordedCallbackAction {
  double recordedLength;
  List<int> recordedFrame;
  RecordedCallbackAction(this.recordedLength, this.recordedFrame);
}

class RecordedCallbackUpdateAction {
  String statusAreaText;
  double recordedLength;
  List<int> combinedFrame;
  double combinedDuration;
  RecordedCallbackUpdateAction(this.statusAreaText, this.recordedLength,
      this.combinedFrame, this.combinedDuration);
}

class IncomingTranscriptAction {
  Pair<String, double> transcript;
  IncomingTranscriptAction(this.transcript);
}

ThunkAction<AppState> processCurrentAudioFile = (Store<AppState> store) async {
  final double audioLength = store.state.audio.duration.toDouble();
  final UntitledState state = store.state.untitled;
  if (state.leopard == null || state.file == null) {
    return;
  }

  store.dispatch(StartProcessingAudioFileAction());

  List<int>? frames = await MicRecorder.getFramesFromFile(state.file!);
  if (frames == null) {
    print('Did not get any frames from audio file');
    return;
  }

  Stopwatch stopwatch = Stopwatch()..start();
  List<List<int>> allFrames = frames.split(12000);
  List<int> data = [];

  for (final frame in allFrames) {
    data.addAll(frame);
    await store.dispatch(
        getRecordedCallback(data.length / state.leopard!.sampleRate, frame));
  }

  Duration elapsed = stopwatch.elapsed;

  String transcriptionTime = (elapsed.inMilliseconds / 1000).toStringAsFixed(1);

  final successText =
      "Transcribed ${audioLength.toStringAsFixed(1)}(s) of audio in $transcriptionTime(s)";
};

ThunkAction<AppState> Function(double, List<int>) getRecordedCallback =
    (double length, List<int> frame) {
  return (Store<AppState> store) async {
    if (length < maxRecordingLengthSecs) {
      final statusAreaText =
          "Recording : ${length.toStringAsFixed(1)} / $maxRecordingLengthSecs seconds";

      String singleFrameTranscript =
          await store.state.untitled.leopard!.process(frame);
      UntitledState state = store.state.untitled;

      List<int> newCombinedFrame = state.combinedFrame;
      newCombinedFrame.addAll(frame);

      double newCombinedDuration = state.combinedDuration +
          (frame.length / state.micRecorder!.sampleRate);

      if (singleFrameTranscript == null ||
          singleFrameTranscript.trim().isEmpty) {
        print('potential end point, duration: $newCombinedDuration');

        if (newCombinedDuration > 4) {
          final double startTime = max(0, length - newCombinedDuration);

          // we want the startTime of the text rather than the end
          Pair<String, double> incomingTranscript =
              await state.processCombined(newCombinedFrame, startTime);
          await store.dispatch(IncomingTranscriptAction(incomingTranscript));
          // newCombinedDuration = 0.0;
          // newCombinedFrame = [];

        } else {
          await store.dispatch(RecordedCallbackUpdateAction(
              statusAreaText, length, newCombinedFrame, newCombinedDuration));
        }
      } else {
        await store.dispatch(RecordedCallbackUpdateAction(
            statusAreaText, length, newCombinedFrame, newCombinedDuration));
      }
    } else {
      await store.state.untitled.stopRecording();
    }
  };
};

// Individual Reducers.
// Each reducer will handle actions related to the State Tree it cares about!
UntitledState untitledReducer(UntitledState prevState, action) {
  if (action is! AudioPositionChangeAction) {
    print(action);
  }
  if (action is InitAction) {
    return prevState.copyWith(
        leopard: action.leopard, micRecorder: action.micRecorder);
  } else if (action is HighlightSpanAtIndex) {
    int newIndex = action.index;
    return prevState.copyWith(
        highlightedSpanIndex:
            newIndex == prevState.highlightedSpanIndex ? null : newIndex);
  } else if (action is AudioFileChangeAction) {
    print('files are equal: ${action.file == prevState.file}');
    return prevState.copyWith(file: action.file, shouldOverrideFile: true);
  } else if (action is StartRecordSuccessAction) {
    return prevState.copyWith(
        transcriptTextList: [],
        highlightedSpanIndex: null,
        combinedFrame: [],
        combinedDuration: 0.0,
        isRecording: true);
  } else if (action is StopRecordSucessAction) {
    final newTranscriptTextList = prevState.transcriptTextList;
    newTranscriptTextList.add(action.remainingTranscript);
    return prevState.copyWith(
        transcriptTextList: newTranscriptTextList,
        isRecording: false,
        shouldOverrideFile: true);
  } else if (action is StartProcessingAudioFileAction) {
    return prevState.copyWith(
        transcriptTextList: [],
        highlightedSpanIndex: null,
        combinedFrame: [],
        combinedDuration: 0.0,
        statusAreaText: "Transcribing, please wait...");
  } else if (action is ProcessAudioFileSuccessAction) {
    return prevState.copyWith(
        statusAreaText: action.statusAreaText,
        transcriptTextList: action.transcriptTextList);
  } else if (action is IncomingTranscriptAction) {
    final newTranscriptTextList = prevState.transcriptTextList;
    newTranscriptTextList.add(action.transcript);
    return prevState.copyWith(
        transcriptTextList: newTranscriptTextList,
        combinedFrame: [],
        combinedDuration: 0.0);
  } else if (action is RecordedCallbackUpdateAction) {
    return prevState.copyWith(
        statusAreaText: action.statusAreaText,
        recordedLength: action.recordedLength,
        combinedFrame: action.combinedFrame,
        combinedDuration: action.combinedDuration);
  } else if (action is ErrorCallbackAction) {
    return prevState.copyWith(errorMessage: action.errorMessage);
  } else {
    return prevState;
  }
}
