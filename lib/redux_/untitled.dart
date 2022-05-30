import 'dart:io';
import 'dart:math';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:file_picker/file_picker.dart';
import 'package:leopard_demo/mic_recorder.dart';
import 'package:leopard_demo/redux_/audio.dart';
import 'package:leopard_demo/utils/global_variables.dart';
import 'package:leopard_demo/utils/utils.dart';

import 'package:leopard_flutter/leopard.dart';
import 'package:leopard_flutter/leopard_error.dart';

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

  @override
  String toString() {
    return 'file: $file \ncombinedDuration: $combinedDuration \n$leopard \nMicRecorder: $micRecorder \nTranscript: $transcriptTextList';
  }

  static UntitledState empty() {
    final empty = UntitledState(
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
    return empty;
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
      errorMessage: errorMessage,
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
      file: file,
    );
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
          leopard.sampleRate,
          store.state.untitled.recordedCallbackThunk(leopard),
          store.state.untitled.errorCallback);
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
    AudioState.stopPlayer();
    store.dispatch(AudioFileChangeAction(null));
  }

  // Recorder Functions
  Future<void> startRecording() async {
    if (isRecording || micRecorder == null) {
      return;
    }
    try {
      micRecorder!.startRecord().then((value) {
        store.dispatch(StartRecordSuccessAction());
        print('Started recording: $transcriptTextList');
      });
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

  recordedCallbackThunk(Leopard leopard) {
    return (double length, List<int> frame) async {
      print("CALLBACK with $leopard");

      if (length < maxRecordingLengthSecs) {
        final statusAreaText =
            "Recording : ${length.toStringAsFixed(1)} / $maxRecordingLengthSecs seconds";

        final String transcript = await leopard.process(frame);

        store.dispatch(RecordedCallbackAction(length, frame, transcript));
      } else {
        await stopRecording();
      }
    };
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

// class RecordedCallbackAction {
//   String statusAreaText;
//   double recordedLength;
//   List<int> combinedFrame;
//   double combinedDuration;
//   RecordedCallbackAction(this.statusAreaText, this.recordedLength,
//       this.combinedFrame, this.combinedDuration);
// }
class RecordedCallbackAction {
  double length;
  List<int> frame;
  String transcript;
  RecordedCallbackAction(this.length, this.frame, this.transcript);
}

class IncomingTranscriptAction {
  Pair<String, double> transcript;
  double length;
  IncomingTranscriptAction(this.transcript, this.length);
}

// Individual Reducers.
// Each reducer will handle actions related to the State Tree it cares about!
UntitledState untitledReducer(UntitledState prevState, action) {
  print(action);
  print('Previous State: $prevState');
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
    print(newTranscriptTextList);
    return prevState.copyWith(
        recordedLength: action.length,
        transcriptTextList: newTranscriptTextList,
        combinedFrame: [],
        combinedDuration: 0.0);
  } else if (action is RecordedCallbackAction) {
    final List<int> newCombinedFrame = prevState.combinedFrame;
    newCombinedFrame.addAll(action.frame);

    final double newCombinedDuration = prevState.combinedDuration +
        (action.frame.length / prevState.leopard!.sampleRate);
    print(
        'before duration: $prevState.combinedDuration, after duration: $newCombinedDuration');

    if (action.transcript.trim().isEmpty) {
      print('potential end point');
      if (newCombinedDuration > 4) {
        final double startTime = max(0, action.length - newCombinedDuration);
        print('dispatching transcript');
        // we want the startTimeof the text rather than the end
        prevState.processCombined(newCombinedFrame, startTime).then((value) {
          return store.dispatch(IncomingTranscriptAction(value, action.length));
        });
      }
    }

    return prevState.copyWith(
        recordedLength: action.length,
        combinedFrame: newCombinedFrame,
        combinedDuration: newCombinedDuration);
  } else if (action is ErrorCallbackAction) {
    return prevState.copyWith(errorMessage: action.errorMessage);
  } else {
    return prevState;
  }
}
