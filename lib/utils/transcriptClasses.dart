import 'dart:convert';
import 'dart:io';

import 'package:Minutes/redux_/files.dart';
import 'package:Minutes/utils/alert_dialog.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../redux_/rootStore.dart';
import 'package:path/path.dart' as path;

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

class SaveFile {
  final List<TranscriptPair> transcript;
  File audio;
  SaveFile(this.audio, this.transcript);

  Map toJson() => {'transcript': transcript, 'audio': audio.name};

  static Future<SaveFile> fromJson(Map<String, dynamic> map) async {
    final Directory filesDirectory =
        await TranscriptFileHandler.appFilesDirectory;

    final File audio = File(path.join(filesDirectory.path, map['audio']));

    final List<TranscriptPair> transcript = (map['transcript'] as List<dynamic>)
        .map((item) => TranscriptPair.fromJson(item))
        .toList();

    return SaveFile(audio, transcript);
  }

  @override
  bool operator ==(final Object other) {
    return other is SaveFile &&
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

  static final Future<Directory> appFilesDirectory = appRootDirectory.then(
      (dir) => Directory(path.join(dir.path, 'files')).create(recursive: true));

  static Future<void> save(BuildContext context, SaveFile transcript,
      {bool force = false}) async {
    // Need to check that filename is not duplicate and non-empty
    try {
      final Directory dir = await appFilesDirectory;
      final String saveFilePath =
          path.join(dir.path, '${transcript.audio.nameWithoutExtension}.txt');

      if (!force && await File(saveFilePath).exists()) {
        showAlertDialog(context, 'Replace Existing File?',
            'The file ${transcript.audio.nameWithoutExtension} already exists.',
            actions: [
              TextButton(
                  onPressed: () => save(context, transcript, force: true)
                      .then((_) => Navigator.of(context).pop()),
                  child: const Text('Replace')),
              TextButton(
                  onPressed: () async {
                    String newPath =
                        (await transcript.audio.getNonDuplicate()).path;
                    File newAudio = await transcript.audio.copy(newPath);
                    SaveFile newTranscript =
                        SaveFile(newAudio, transcript.transcript);
                    save(context, newTranscript)
                        .then((_) => Navigator.of(context).pop());
                  },
                  child: const Text('Keep Both')),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Stop'),
              ),
            ]);
        return;
      }

      final File saveFile = await File(saveFilePath).create(recursive: true);

      // Copy audio file to app documents
      final String audioFilePath = path.join(dir.path, transcript.audio.name);
      transcript.audio = await transcript.audio.copy(audioFilePath);

      await saveFile.writeAsString(jsonEncode(transcript));

      print('saved to $saveFilePath');
    } catch (err) {
      showAlertDialog(context, 'Error saving file', err.toString());
    }
  }

  static Future<SaveFile> load(String path) async {
    String transcriptFile = await File(path).readAsString();
    print(transcriptFile);
    return SaveFile.fromJson(jsonDecode(transcriptFile));
  }

  static Future<void> delete(BuildContext context, SaveFile transcript) async {
    try {
      final Directory dir = await appFilesDirectory;
      final String saveFilePath =
          path.join(dir.path, '${transcript.audio.nameWithoutExtension}.txt');

      transcript.audio.delete().then((_) => File(saveFilePath)
          .delete()
          .then((_) => store.dispatch(refreshFiles)));
    } catch (err) {
      showAlertDialog(context, 'Error deleting file', err.toString());
    }
  }
}
