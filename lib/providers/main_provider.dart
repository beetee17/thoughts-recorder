import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:leopard_demo/mic_recorder.dart';
import 'package:leopard_demo/utils/global_variables.dart';

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

  String _transcriptText = "";
  String get transcriptText => _transcriptText;

  MicRecorder? _micRecorder;
  Leopard? _leopard;

  File? _file;
  File? get file => _file;

  Future<int> binarySearch(int transcriptIndex) async {
    if (_micRecorder == null || _leopard == null) {
      return -1;
    }
    List<String> list = transcriptText.split(' ');
    List<int> pcmData = _micRecorder!.pcmData;

    int min = 0;
    int max = pcmData.length - 1;

    while (min <= max) {
      print('$min, $max');
      int mid = ((min + max) / 2).floor();
      int res = await _leopard!.process(pcmData.sublist(0, mid)).then((s) {
        return s.split(' ').length - 1;
      });

      if (transcriptIndex == res) {
        print("Found word: ${list[transcriptIndex]} at Index $mid");
        return mid;
      } else if (transcriptIndex < res) {
        max = mid - 1;
      } else {
        min = mid + 1;
      }
    }

    print("Not found");
    return -1;
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
      _file = await _micRecorder!.stopRecord();
      _statusAreaText = "Transcribing, please wait...";
      _isRecording = false;
      notifyListeners();
      processRecording();
    } on LeopardException catch (ex) {
      print("Failed to stop audio capture: ${ex.message}");
    }
  }

  /// Processes given audio data and sets the [transcriptionText].
  ///
  /// [audioLength] If this optional parameter is given, this means it is a user uploaded file.
  ///
  Future<void> processRecording({double? audioLength}) async {
    if (_leopard == null) {
      return;
    }
    _statusAreaText = "Transcribing, please wait...";

    Stopwatch stopwatch = Stopwatch()..start();
    String? transcript = await _leopard?.processFile(_file!.path);
    Duration elapsed = stopwatch.elapsed;

    String recordedLength = _recordedLength.toStringAsFixed(1);

    String transcriptionTime =
        (elapsed.inMilliseconds / 1000).toStringAsFixed(1);

    _statusAreaText =
        "Transcribed ${audioLength == null ? recordedLength : audioLength.toStringAsFixed(1)}(s) of audio in $transcriptionTime(s)";
    _transcriptText = transcript ?? "";

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

  Future<void> recordedCallback(double length) async {
    if (length < maxRecordingLengthSecs) {
      _recordedLength = length;
      _statusAreaText =
          "Recording : ${length.toStringAsFixed(1)} / $maxRecordingLengthSecs seconds";

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
