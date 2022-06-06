import 'dart:convert';
import 'dart:io';

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
  final File audio;
  const Transcript(this.audio, this.transcript);

  Map toJson() => {'transcript': transcript, 'audio': audio.path};

  Transcript.fromJson(Map<String, dynamic> map)
      : transcript = (map['transcript'] as List<dynamic>)
            .map((item) => TranscriptPair.fromJson(item))
            .toList(),
        audio = File(map['audio']);
}

class TranscriptFileHandler {
  static final Future<Directory> directory = getApplicationDocumentsDirectory();
  static void save(Transcript transcript) async {
    final Directory dir = await directory;

    final File saveFile =
        await File('${dir.path}/files/testing.txt').create(recursive: true);

    saveFile.writeAsString(jsonEncode(transcript));
  }

  static Future<Transcript> load(String path) async {
    String transcriptFile = await File(path).readAsString();
    return Transcript.fromJson(jsonDecode(transcriptFile));
  }

  static Future<void> loadTest() async {
    final Directory dir = await directory;
    String transcriptFile =
        await File('${dir.path}/files/testing.txt').readAsString();

    final decodedJSON = jsonDecode(transcriptFile);
    print(decodedJSON);

    Transcript test = Transcript.fromJson(decodedJSON);
    print(test);
  }
}
