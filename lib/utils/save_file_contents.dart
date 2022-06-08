import 'dart:io';

import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/transcriptClasses.dart';
import 'package:Minutes/utils/transcript_pair.dart';

import 'package:path/path.dart' as path;

class SaveFileContents {
  final List<TranscriptPair> transcript;
  File audio;
  SaveFileContents(this.audio, this.transcript);

  Map toJson() => {'transcript': transcript, 'audio': audio.name};

  static Future<SaveFileContents> fromJson(Map<String, dynamic> map) async {
    final Directory filesDirectory =
        await TranscriptFileHandler.appFilesDirectory;
    print('files at ${filesDirectory.path}');
    final File audio = File(path.join(filesDirectory.path, map['audio']));

    final List<TranscriptPair> transcript = (map['transcript'] as List<dynamic>)
        .map((item) => TranscriptPair.fromJson(item))
        .toList();

    return SaveFileContents(audio, transcript);
  }

  @override
  bool operator ==(final Object other) {
    return other is SaveFileContents &&
        transcript == other.transcript &&
        audio == other.audio;
  }

  @override
  int get hashCode => Object.hash(transcript, audio);

  @override
  String toString() => '(${transcript.toString()}, ${audio.path})';
}
