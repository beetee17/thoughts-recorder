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

  File? _userSelectedFile;
  File? get userSelectedFile => _userSelectedFile;

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
        _userSelectedFile = File(res.files.single.path!);
        notifyListeners();
      } else {
        // User canceled the picker
      }
    });
  }

  void removeSelectedFile() {
    _userSelectedFile = null;
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
      File recordedFile = await _micRecorder!.stopRecord();
      _statusAreaText = "Transcribing, please wait...";
      _isRecording = false;
      notifyListeners();
      _processAudio(recordedFile);
    } on LeopardException catch (ex) {
      print("Failed to stop audio capture: ${ex.message}");
    }
  }

  Future<void> _processAudio(File recordedFile) async {
    if (_leopard == null) {
      return;
    }

    Stopwatch stopwatch = Stopwatch()..start();
    print(_userSelectedFile?.path);
    String? transcript = await _leopard?.processFile(_userSelectedFile == null
        ? recordedFile.path
        : _userSelectedFile!.path);
    Duration elapsed = stopwatch.elapsed;

    String audioLength = _recordedLength.toStringAsFixed(1);
    String transcriptionTime =
        (elapsed.inMilliseconds / 1000).toStringAsFixed(1);

    _statusAreaText =
        "Transcribed ${audioLength}(s) of audio in ${transcriptionTime}(s)";
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
          "Recording : ${length.toStringAsFixed(1)} / ${maxRecordingLengthSecs} seconds";

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
