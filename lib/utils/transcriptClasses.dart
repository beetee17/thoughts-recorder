import 'dart:convert';
import 'dart:io';

import 'package:Minutes/utils/extensions.dart';
import 'package:path_provider/path_provider.dart';

class TranscriptPair {
  final String text;
  final Duration startTime;
  TranscriptPair(this.text, this.startTime);

  TranscriptPair map(String Function(String) leftMapper,
      Duration Function(Duration) rightMapper) {
    return TranscriptPair(leftMapper(text), rightMapper(startTime));
  }

  Map toJson() => {'text': text, 'startTime': startTime.inMilliseconds};

  TranscriptPair.fromJson(Map<String, dynamic> map)
      : text = map['text'],
        startTime = Duration(milliseconds: map['startTime']);

  @override
  bool operator ==(final Object other) {
    return other is TranscriptPair &&
        text == other.text &&
        startTime == other.startTime;
  }

  @override
  int get hashCode => Object.hash(text, startTime);

  @override
  String toString() => '(${text.toString()}, ${startTime.toString()})';
}

class Transcript {
  final List<TranscriptPair> transcript;
  File audio;
  Transcript(this.audio, this.transcript);

  Map toJson() => {'transcript': transcript, 'audio': audio.path};

  Transcript.fromJson(Map<String, dynamic> map)
      : transcript = (map['transcript'] as List<dynamic>)
            .map((item) => TranscriptPair.fromJson(item))
            .toList(),
        audio = File(map['audio']);

  @override
  bool operator ==(final Object other) {
    return other is Transcript &&
        transcript == other.transcript &&
        audio == other.audio;
  }

  @override
  int get hashCode => Object.hash(transcript, audio);

  @override
  String toString() => '(${transcript.toString()}, ${audio.path})';
}

class TranscriptFileHandler {
  static final Future<Directory> appRootDirectory =
      getApplicationDocumentsDirectory();

  static final Future<Directory> appFilesDirectory = appRootDirectory
      .then((dir) => Directory('${dir.path}/files').create(recursive: true));

  static void save(Transcript transcript) async {
    final Directory dir = await appFilesDirectory;
    final String filename = transcript.audio.getFileName();

    final File saveFile = await File('${dir.absolute.path}/$filename.txt')
        .create(recursive: true);

    // Copy audio file to app documents
    transcript.audio =
        await transcript.audio.copy('${dir.absolute.path}/$filename');
    await saveFile.writeAsString(jsonEncode(transcript));

    print('saved to ${saveFile.path}');
  }

  static Future<Transcript> load(String path) async {
    String transcriptFile = await File(path).readAsString();

    return Transcript.fromJson(jsonDecode(transcriptFile));
  }
}
