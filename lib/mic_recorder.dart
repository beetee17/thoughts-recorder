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
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/services.dart';
import 'package:flutter_voice_processor/flutter_voice_processor.dart';
import 'package:Minutes/redux_/recorder.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/redux_/status.dart';
import 'package:Minutes/utils/global_variables.dart';
import 'package:leopard_flutter/leopard_error.dart';
import 'package:path_provider/path_provider.dart';

typedef ProcessErrorCallback = Function(LeopardException error);

class MicRecorder {
  final VoiceProcessor? _voiceProcessor;
  int _sampleRate;
  int get sampleRate => _sampleRate;

  final ProcessErrorCallback _processErrorCallback;
  RemoveListener? _removeVoiceProcessorListener;
  RemoveListener? _removeErrorListener;

  List<int> _pcmData = [];
  List<int> combinedFrame = [];
  int count = 0;

  static Future<MicRecorder> create(
      int sampleRate, ProcessErrorCallback processErrorCallback) async {
    return MicRecorder._(sampleRate, processErrorCallback);
  }

  MicRecorder._(this._sampleRate, this._processErrorCallback)
      : _voiceProcessor = VoiceProcessor.getVoiceProcessor(512, _sampleRate) {
    if (_voiceProcessor == null) {
      throw LeopardRuntimeException("flutter_voice_processor not available.");
    }
    _removeVoiceProcessorListener =
        _voiceProcessor!.addListener((buffer) async {
      List<int> frame;
      try {
        frame = (buffer as List<dynamic>).cast<int>();
      } on Error {
        LeopardException castError = LeopardException(
            "flutter_voice_processor sent an unexpected data type.");
        _processErrorCallback(castError);
        return;
      }

      _pcmData.addAll(frame);
      if (count != 0 && count % 35 == 0) {
        final Duration recordedLength = Duration(
            milliseconds: (_pcmData.length / _sampleRate * 1000).toInt());
        store.dispatch(StatusTextChangeAction(
            "Recording : ${(recordedLength.inMilliseconds / 1000).toStringAsFixed(1)} / ${maxRecordingLength.inSeconds} seconds"));
        store.dispatch(getRecordedCallback(recordedLength, combinedFrame));
        combinedFrame = [];
      } else {
        combinedFrame.addAll(frame);
      }
      count++;
    });

    _removeErrorListener = _voiceProcessor!.addErrorListener((errorMsg) {
      LeopardException nativeError = LeopardException(errorMsg as String);
      _processErrorCallback(nativeError);
    });
  }

  Future<void> startRecord() async {
    if (_voiceProcessor == null) {
      throw LeopardInvalidStateException(
          "Cannot start audio recording - resources have already been released");
    }

    if (await _voiceProcessor?.hasRecordAudioPermission() ?? false) {
      try {
        await _voiceProcessor!.start();
      } on PlatformException {
        throw LeopardRuntimeException(
            "Audio engine failed to start. Hardware may not be supported.");
      }
    } else {
      throw LeopardRuntimeException(
          "User did not give permission to record audio.");
    }
  }

  Future<void> clearData() async {
    _pcmData.clear();
  }

  Future<File> stopRecord() async {
    if (_voiceProcessor == null) {
      throw LeopardInvalidStateException(
          "Cannot stop audio recording - resources have already been released");
    }

    if (_voiceProcessor?.isRecording ?? false) {
      await _voiceProcessor!.stop();
    }

    try {
      return await writeWavFile();
    } catch (e) {
      throw LeopardIOException("Failed to save recorded audio to file.");
    }
  }

  Future<void> pauseRecord() async {
    if (_voiceProcessor == null) {
      throw LeopardInvalidStateException(
          "Cannot pause audio recording - resources have already been released");
    }

    if (_voiceProcessor?.isRecording ?? false) {
      await _voiceProcessor!.stop();
    }
  }

  Future<File> writeWavFile() async {
    final int channelCount = 1;
    final int bitDepth = 16;
    final int sampleRate = 16000;

    final directory = await getApplicationDocumentsDirectory();
    final wavFile = File('${directory.path}/recording.wav');

    final bytesBuilder = BytesBuilder();

    void writeString(String s) {
      final stringBuffer = utf8.encode(s);
      bytesBuilder.add(stringBuffer);
    }

    void writeUint32(int value) {
      final uint32Buffer = Uint8List(4)
        ..buffer.asByteData().setUint32(0, value, Endian.little);
      bytesBuilder.add(uint32Buffer);
    }

    void writeUint16(int value) {
      final uint16Buffer = Uint8List(2)
        ..buffer.asByteData().setUint16(0, value, Endian.little);
      bytesBuilder.add(uint16Buffer);
    }

    void writeInt16(int value) {
      final int16Buffer = Uint8List(2)
        ..buffer.asByteData().setInt16(0, value, Endian.little);
      bytesBuilder.add(int16Buffer);
    }

    writeString('RIFF');
    writeUint32(((bitDepth / 8) * _pcmData.length + 36).toInt());
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16);
    writeUint16(1);
    writeUint16(channelCount);
    writeUint32(sampleRate);
    writeUint32(((sampleRate * channelCount * bitDepth) / 8).toInt());
    writeUint16(((channelCount * bitDepth) / 8).toInt());
    writeUint16(bitDepth);
    writeString('data');
    writeUint32(((bitDepth / 8) * _pcmData.length).toInt());

    for (int i = 0; i < _pcmData.length; i++) {
      writeInt16(_pcmData[i]);
    }

    return wavFile.writeAsBytes(bytesBuilder.toBytes());
  }

  static Future<List<int>?> getFramesFromFile(File file) async {
    final directory = await getApplicationDocumentsDirectory();
    final String outputFilePath = '${directory.path}/output.pcm';

    // see https://stackoverflow.com/questions/4854513/can-ffmpeg-convert-audio-to-raw-pcm-if-so-how
    final session = await FFmpegKit.execute(
        '-y -i "${file.path}" -acodec pcm_s16le -f s16le -ac 1 -ar 16000 "$outputFilePath"');

    final returnCode = await session.getReturnCode();

    // see https://stackoverflow.com/questions/59877602/how-to-get-byte-data-from-audio-file-must-be-as-signed-int-bytes-in-flutter
    if (ReturnCode.isSuccess(returnCode)) {
      File outputFile = File(outputFilePath);
      Uint8List bytes = await outputFile.readAsBytes();
      return bytes.buffer.asInt16List();
    }
    return null;
  }
}
