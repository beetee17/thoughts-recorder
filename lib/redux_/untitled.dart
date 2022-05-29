import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:leopard_demo/mic_recorder.dart';
import 'package:leopard_demo/redux_/audio.dart';
import 'package:leopard_demo/utils/global_variables.dart';
import 'package:leopard_demo/utils/utils.dart';

import 'package:leopard_flutter/leopard.dart';
import 'package:leopard_flutter/leopard_error.dart';

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/utils/extensions.dart';

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
      required this.transcriptTextList}) {
    initLeopard();
  }

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

  UntitledState copyWith({
    String? errorMessage,
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
  }) {
    return UntitledState(
      errorMessage: errorMessage ?? this.errorMessage,
      isRecording: isRecording ?? this.isRecording,
      isProcessing: isProcessing ?? this.isProcessing,
      recordedLength: recordedLength ?? this.recordedLength,
      statusAreaText: statusAreaText ?? this.statusAreaText,
      combinedFrame: combinedFrame ?? this.combinedFrame,
      combinedDuration: combinedDuration ?? this.combinedDuration,
      transcriptTextList: transcriptTextList ?? this.transcriptTextList,
      highlightedSpanIndex: highlightedSpanIndex ?? this.highlightedSpanIndex,
      micRecorder: micRecorder ?? this.micRecorder,
      leopard: leopard ?? this.leopard,
      file: file ?? this.file,
    );
  }

  Future<void> initLeopard() async {
    if (leopard != null && micRecorder != null) {
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
          leopard.sampleRate, recordedCallback, errorCallback);
      store.dispatch(InitAction(leopard, micRecorder));
    } on LeopardInvalidArgumentException catch (ex) {
      errorCallback(LeopardInvalidArgumentException(
          "${ex.message}\nEnsure your accessKey '$accessKey' is a valid access key."));
    } on LeopardActivationException {
      errorCallback(LeopardActivationException("AccessKey activation error."));
    } on LeopardActivationLimitException {
      errorCallback(LeopardActivationLimitException(
          "AccessKey reached its device limit."));
    } on LeopardActivationRefusedException {
      errorCallback(LeopardActivationRefusedException("AccessKey refused."));
    } on LeopardActivationThrottledException {
      errorCallback(
          LeopardActivationThrottledException("AccessKey has been throttled."));
    } on LeopardException catch (ex) {
      errorCallback(ex);
    }
  }

// File Picker Functions
  void pickFile() {
    // From SDK Documentation:
    // The file needs to have a sample rate equal to or greater than Leopard.sampleRate.
    //The supported formats are: FLAC, MP3, Ogg, Opus, Vorbis, WAV, and WebM.
    FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: [
      'flac',
      'mp3',
      'ogg',
      'opus',
      'wav',
      'webm'
    ]).then((res) {
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
    return Pair(transcript, startTime);
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

      store.dispatch(StopRecordSucessAction(file, remainingTranscript));
    } on LeopardException catch (ex) {
      print("Failed to stop audio capture: ${ex.message}");
    }
  }

  /// Processes given audio data and sets the [transcriptionText].
  ///
  /// [audioLength] If this optional parameter is given, this means it is a user uploaded file.
  ///
  Future<void> processCurrentAudioFile(double audioLength) async {
    if (leopard == null || file == null) {
      return;
    }

    store.dispatch(ProcessingAudioFileAction());

    Stopwatch stopwatch = Stopwatch()..start();
    String transcript = await leopard!.processFile(file!.path);
    Duration elapsed = stopwatch.elapsed;

    String transcriptionTime =
        (elapsed.inMilliseconds / 1000).toStringAsFixed(1);

    final successText =
        "Transcribed ${audioLength.toStringAsFixed(1)}(s) of audio in $transcriptionTime(s)";
    final transcriptTextList = [Pair(transcript, 0.0)];

    store.dispatch(
        ProcessAudioFileSuccessAction(successText, transcriptTextList));
  }

  Future<void> recordedCallback(double length, List<int> frame) async {
    if (length < maxRecordingLengthSecs) {
      final statusAreaText =
          "Recording : ${length.toStringAsFixed(1)} / $maxRecordingLengthSecs seconds";

      final String transcript = await leopard!.process(frame);
      // print(text);
      final List<int> newCombinedFrame = combinedFrame;
      newCombinedFrame.addAll(frame);

      final double newCombinedDuration =
          combinedDuration + (frame.length / micRecorder!.sampleRate);

      store.dispatch(RecordedCallbackAction(
          statusAreaText, length, newCombinedFrame, newCombinedDuration));

      if (transcript == null || transcript.trim().isEmpty) {
        print('potential end point');
        if (newCombinedDuration > 4) {
          final double startTime = max(0, length - newCombinedDuration);

          // we want the startTimeof the text rather than the end
          processCombined(combinedFrame, startTime).then((value) {
            store.dispatch(IncomingTranscriptAction(value));
          });
        }
      }
    } else {
      await stopRecording();
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
  File file;
  Pair<String, double> remainingTranscript;
  StopRecordSucessAction(this.file, this.remainingTranscript);
}

class ProcessingAudioFileAction {}

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
  String statusAreaText;
  double recordedLength;
  List<int> combinedFrame;
  double combinedDuration;
  RecordedCallbackAction(this.statusAreaText, this.recordedLength,
      this.combinedFrame, this.combinedDuration);
}

class IncomingTranscriptAction {
  Pair<String, double> transcript;
  IncomingTranscriptAction(this.transcript);
}

// Individual Reducers.
// Each reducer will handle actions related to the State Tree it cares about!
UntitledState untitledReducer(UntitledState prevState, action) {
  if (action is InitAction) {
    return prevState.copyWith(
        leopard: action.leopard, micRecorder: action.micRecorder);
  } else if (action is HighlightSpanAtIndex) {
    int newIndex = action.index;
    return prevState.copyWith(
        highlightedSpanIndex:
            newIndex == prevState.highlightedSpanIndex ? null : newIndex);
  } else if (action is AudioFileChangeAction) {
    return prevState.copyWith(file: action.file);
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
        file: action.file,
        transcriptTextList: newTranscriptTextList,
        isRecording: false);
  } else if (action is ProcessingAudioFileAction) {
    return prevState.copyWith(statusAreaText: "Transcribing, please wait...");
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
  } else if (action is RecordedCallbackAction) {
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
