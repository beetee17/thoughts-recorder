//
// Copyright 2022 Picovoice Inc.
//
// You may not use this file except in compliance with the license. A copy of the license is located in the "LICENSE"
// file accompanying this source.
//
// Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leopard_demo/mic_recorder.dart';
import 'package:leopard_demo/widgets/audio_player.dart';
import 'package:leopard_demo/widgets/error_message.dart';
import 'package:leopard_demo/widgets/share_transcript_button.dart';
import 'package:leopard_demo/widgets/selected_file.dart';
import 'package:leopard_demo/widgets/status_area.dart';
import 'package:leopard_demo/widgets/text_area.dart';
import 'package:leopard_flutter/leopard.dart';
import 'package:leopard_flutter/leopard_error.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String accessKey =
      '3oGp4ivh8O72YYazPiNsioX6z4eM78P0yReachZZPqmwm4wjkxuWUg=='; // AccessKey obtained from Picovoice Console (https://console.picovoice.ai/)
  final int maxRecordingLengthSecs = 60000; // 1 Hour

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? errorMessage;

  bool isRecording = false;
  bool isProcessing = false;
  double recordedLength = 0.0;
  String statusAreaText = "";
  String transcriptText = "";

  MicRecorder? _micRecorder;
  Leopard? _leopard;

  File? _userSelectedFile;

  @override
  void initState() {
    super.initState();
    setState(() {
      recordedLength = 0.0;
      statusAreaText =
          "Press START to start recording some audio to transcribe";
      transcriptText = "";
    });

    initLeopard();
  }

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
    ]).then((res) => {
          if (res != null)
            {
              setState(() {
                _userSelectedFile = File(res.files.single.path!);
              })
            }
          else
            {
              // User canceled the picker
            }
        });
  }

  void removeSelectedFile() {
    setState(() {
      _userSelectedFile = null;
    });
  }

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
      setState(() {
        recordedLength = length;
        statusAreaText =
            "Recording : ${length.toStringAsFixed(1)} / ${maxRecordingLengthSecs} seconds";
      });
    } else {
      setState(() {
        recordedLength = length;
        statusAreaText = "Transcribing, please wait...";
      });
      await _stopRecording();
    }
  }

  void errorCallback(LeopardException error) {
    setState(() {
      errorMessage = error.message!;
    });
  }

  Future<void> _startRecording() async {
    if (isRecording || _micRecorder == null) {
      return;
    }

    try {
      await _micRecorder!.startRecord();
      setState(() {
        isRecording = true;
      });
    } on LeopardException catch (ex) {
      print("Failed to start audio capture: ${ex.message}");
    }
  }

  Future<void> _stopRecording() async {
    if (!isRecording || _micRecorder == null) {
      return;
    }

    try {
      File recordedFile = await _micRecorder!.stopRecord();
      setState(() {
        statusAreaText = "Transcribing, please wait...";
        isRecording = false;
      });
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

    String audioLength = recordedLength.toStringAsFixed(1);
    String transcriptionTime =
        (elapsed.inMilliseconds / 1000).toStringAsFixed(1);

    setState(() {
      statusAreaText =
          "Transcribed ${audioLength}(s) of audio in ${transcriptionTime}(s)";
      transcriptText = transcript ?? "";
    });
  }

  Color picoBlue = Color.fromRGBO(55, 125, 255, 1);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Thoughts Recorder'),
          backgroundColor: picoBlue,
        ),
        body: Column(
          children: [
            TextArea(
                textEditingController:
                    TextEditingController(text: transcriptText)),
            ErrorMessage(errorMessage: errorMessage),
            StatusArea(statusAreaText: statusAreaText),
            Row(
              children: [
                buildStartButton(context),
                buildChooseFilesButton(context),
                SaveTranscriptButton(transcriptText: transcriptText)
              ],
            ),
            SelectedFile(userSelectedFile: _userSelectedFile),
            SizedBox(
              height: 30,
            )
          ],
        ),
      ),
    );
  }

  buildChooseFilesButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: _userSelectedFile == null ? pickFile : removeSelectedFile,
        child: _userSelectedFile == null
            ? Text('Upload File')
            : Text('Remove File'),
      ),
    );
  }

  buildStartButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: (isRecording) ? _stopRecording : _startRecording,
        child: Text(isRecording ? "Stop" : "Start"),
      ),
    );
  }
}
