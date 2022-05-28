import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:leopard_demo/mic_recorder.dart';
import 'package:leopard_demo/utils/global_variables.dart';
import 'package:leopard_demo/utils/utils.dart';

import 'package:leopard_flutter/leopard.dart';
import 'package:leopard_flutter/leopard_error.dart';

class MainProvider with ChangeNotifier {
  String? _errorMessage;
  String? get errorMessage => errorMessage;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  double _recordedLength = 0.0;

  String _statusAreaText =
      "Press START to start recording some audio to transcribe";
  String get statusAreaText => _statusAreaText;

  List<int> combinedFrame = [];
  double combinedDuration = 0.0;

  List<Pair<String, double>> _transcriptTextList = [];
  int? _highlightedSpanIndex;
  int? get highlightedSpanIndex => _highlightedSpanIndex;

  String get transcriptText =>
      _transcriptTextList.map((p) => p.first).join(' ');
  List<Pair<String, double>> get transcriptTextList => _transcriptTextList;

  MicRecorder? _micRecorder;
  Leopard? _leopard;

  File? _file;
  File? get file => _file;

  void highlightSpan(int index) {
    if (_highlightedSpanIndex == index) {
      _highlightedSpanIndex = null;
    } else {
      _highlightedSpanIndex = index;
    }
    notifyListeners();
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
        _file = File(res.files.single.path!);
        notifyListeners();
      } else {
        // User canceled the picker
      }
    });
  }

  void removeSelectedFile() {
    _file = null;
    notifyListeners();
  }

  // Recorder Functions
  Future<void> startRecording() async {
    if (_isRecording || _micRecorder == null) {
      return;
    }

    try {
      await _micRecorder!.startRecord();
      _transcriptTextList = [];
      _highlightedSpanIndex = null;
      combinedFrame = [];
      combinedDuration = 0.0;
      print('Started recording: $transcriptTextList');
      _isRecording = true;
      notifyListeners();
    } on LeopardException catch (ex) {
      print("Failed to start audio capture: ${ex.message}");
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording || _micRecorder == null) {
      return;
    }

    try {
      _file = null;
      _file = await Future.delayed(
          const Duration(seconds: 1), () => _micRecorder!.stopRecord());
      combinedFrame.addAll(_micRecorder!.combinedFrame);

      final double startTime = max(0, _recordedLength - combinedDuration);
      processCombined(combinedFrame, startTime).then((value) {
        _transcriptTextList.add(value);
        print('Transcribed the remaining frames: $transcriptTextList');
      });

      _isRecording = false;
      notifyListeners();
      // processRecording();
    } on LeopardException catch (ex) {
      print("Failed to stop audio capture: ${ex.message}");
    }
  }

  /// Processes given audio data and sets the [transcriptionText].
  ///
  /// [audioLength] If this optional parameter is given, this means it is a user uploaded file.
  ///
  Future<void> processRecording(double audioLength) async {
    if (_leopard == null) {
      return;
    }
    _statusAreaText = "Transcribing, please wait...";

    Stopwatch stopwatch = Stopwatch()..start();
    String? transcript = await _leopard?.processFile(_file!.path);
    Duration elapsed = stopwatch.elapsed;

    String transcriptionTime =
        (elapsed.inMilliseconds / 1000).toStringAsFixed(1);

    _statusAreaText =
        "Transcribed ${audioLength.toStringAsFixed(1)}(s) of audio in $transcriptionTime(s)";
    _transcriptTextList = [Pair(transcript ?? '', 0)];

    notifyListeners();
  }

  // INITALISER FUNCTIONS
  Future<void> initLeopard() async {
    String platform = Platform.isAndroid
        ? "android"
        : Platform.isIOS
            ? "ios"
            : throw LeopardRuntimeException(
                "This demo supports iOS and Android only.");
    String modelPath = "assets/models/ios/myModel-leopard.pv";

    try {
      _leopard = await Leopard.create(accessKey, modelPath);
      _micRecorder = await MicRecorder.create(
          _leopard!.sampleRate, recordedCallback, errorCallback);
      notifyListeners();
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

  Future<Pair<String, double>> processCombined(
      List<int> combinedFrame, double startTime) async {
    final transcript = await _leopard!.process(combinedFrame);
    return Pair(transcript, startTime);
  }

  Future<void> recordedCallback(double length, List<int> frame) async {
    if (length < maxRecordingLengthSecs) {
      _recordedLength = length;
      _statusAreaText =
          "Recording : ${length.toStringAsFixed(1)} / $maxRecordingLengthSecs seconds";

      final text = await _leopard!.process(frame);
      print(text);

      combinedFrame.addAll(frame);
      combinedDuration += frame.length / _micRecorder!.sampleRate;

      if (text == null || text.trim().isEmpty) {
        print('potential end point');
        if (combinedDuration > 4) {
          final double startTime = max(0, _recordedLength - combinedDuration);

          // we want the startTimeof the text rather than the end
          processCombined(combinedFrame, startTime).then((value) {
            _transcriptTextList.add(value);
            print(transcriptTextList);
          });

          combinedFrame = [];
          combinedDuration = 0.0;
        }
      }
      notifyListeners();
    } else {
      _recordedLength = length;
      _statusAreaText = "Transcribing, please wait...";

      notifyListeners();
      await stopRecording();
    }
  }

  void errorCallback(LeopardException error) {
    _errorMessage = error.message!;
    notifyListeners();
  }
}
