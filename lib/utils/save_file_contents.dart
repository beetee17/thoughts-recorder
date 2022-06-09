import 'dart:io';

import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/save_file_handler.dart';
import 'package:Minutes/utils/transcript_pair.dart';
import 'package:intl/intl.dart';

import 'package:path/path.dart' as path;

class SaveFileContents {
  static DateFormat dateFormat = DateFormat("d MMM yyyy 'at' HH:mm");
  final List<TranscriptPair> transcript;
  File audio;
  DateTime creationDate;
  String get parsedCreationDate => dateFormat.format(creationDate);

  SaveFileContents(this.audio, this.transcript, this.creationDate);

  Map toJson() => {
        'transcript': transcript,
        'audio': audio.name,
        'creationDate': dateFormat.format(creationDate)
      };

  static Future<SaveFileContents> fromJson(Map<String, dynamic> map) async {
    final Directory filesDirectory = await SaveFileHandler.appFilesDirectory;
    print('files at ${filesDirectory.path}');
    final File audio = File(path.join(filesDirectory.path, map['audio']));

    final List<TranscriptPair> transcript = (map['transcript'] as List<dynamic>)
        .map((item) => TranscriptPair.fromJson(item))
        .toList();

    return SaveFileContents(
        audio, transcript, dateFormat.parse(map['creationDate']));
  }

  @override
  bool operator ==(final Object other) {
    return other is SaveFileContents &&
        transcript == other.transcript &&
        audio == other.audio &&
        creationDate == other.creationDate;
  }

  @override
  int get hashCode => Object.hash(transcript, audio, creationDate);

  @override
  String toString() =>
      '(${transcript.toString()}, ${audio.path}, ${dateFormat.format(creationDate)})';
}
