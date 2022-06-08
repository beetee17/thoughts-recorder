import 'dart:convert';
import 'dart:io';

import 'package:Minutes/redux_/files.dart';
import 'package:Minutes/utils/alert_dialog.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/spinner.dart';
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

class TranscriptFileHandler {
  static final Future<Directory> appRootDirectory =
      getApplicationDocumentsDirectory();

  static final Future<Directory> appFilesDirectory = appRootDirectory.then(
      (dir) => Directory(path.join(dir.path, 'files')).create(recursive: true));

  static Future<void> save(
      BuildContext context, SaveFileContents? fileContents, String filename,
      {bool force = false}) async {
    if (fileContents == null) {
      return;
    }
    if (filename.trim().isEmpty) {
      showAlertDialog(
          context, 'Untitled File', 'Please enter a name for your file.');
      return;
    }
    try {
      final Directory dir = await appFilesDirectory;
      final String saveFilePath = path.join(dir.path, '$filename.txt');

      if (!force && File(saveFilePath).existsSync()) {
        await showAlertDialog(context, 'Replace Existing File?',
            'The file $filename already exists.',
            actions: [
              TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final tmpContents = fileContents;
                    await delete(context, await load(saveFilePath));
                    await save(context, tmpContents, filename, force: true);
                  },
                  child: const Text('Replace')),
              TextButton(
                  onPressed: () async {
                    File newSaveFile =
                        await File(saveFilePath).getNonDuplicate();

                    File newAudio = await fileContents.audio.copy(
                        newSaveFile.pathWithoutExtension +
                            fileContents.audio.extension);

                    SaveFileContents newContents =
                        SaveFileContents(newAudio, fileContents.transcript);

                    save(context, newContents, newSaveFile.nameWithoutExtension)
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
      final String audioFilePath =
          path.join(dir.path, filename + fileContents.audio.extension);

      final newContents = SaveFileContents(
          await fileContents.audio.copy(audioFilePath),
          fileContents.transcript);

      await saveFile.writeAsString(jsonEncode(newContents));

      print('saved to $saveFilePath');
    } catch (err) {
      showAlertDialog(context, 'Error saving file', err.toString());
    }
  }

  static Future<SaveFileContents?> load(String path) async {
    try {
      String transcriptFile = await File(path).readAsString();
      print(transcriptFile);
      return SaveFileContents.fromJson(jsonDecode(transcriptFile));
    } catch (err) {
      print("Error loading saved file: $err");
      return null;
    }
  }

  static Future<void> delete(
      BuildContext context, SaveFileContents? transcript) async {
    if (transcript == null) {
      return;
    }
    try {
      final Directory dir = await appFilesDirectory;
      final String saveFilePath =
          path.join(dir.path, '${transcript.audio.nameWithoutExtension}.txt');

      transcript.audio.delete().then((_) => File(saveFilePath).delete());
    } catch (err) {
      showAlertDialog(context, 'Error deleting file', err.toString());
    }
  }

  static Future<void> rename(
      BuildContext context, SaveFileContents? prevContents, String newName,
      {bool force = false}) async {
    if (prevContents == null) {
      return;
    }
    if (newName.trim().isEmpty) {
      showAlertDialog(
          context, 'Untitled File', 'Please enter a name for your file.');
      return;
    }
    try {
      final Directory dir = await appFilesDirectory;
      final String prevName = prevContents.audio.nameWithoutExtension;
      final String prevSavePath = path.join(dir.path, '$prevName.txt');

      final String newSavePath = path.join(dir.path, '$newName.txt');

      if (File(newSavePath).existsSync()) {
        await showAlertDialog(context, 'Unable to Rename File',
            'The file $newName already exists.');
        return;
      }

      final File saveFile = await File(newSavePath).create(recursive: true);

      // Copy audio file to app documents
      final String audioFilePath =
          path.join(dir.path, newName + prevContents.audio.extension);

      final newContents = SaveFileContents(
          await prevContents.audio.copy(audioFilePath),
          prevContents.transcript);

      await saveFile.writeAsString(jsonEncode(newContents));
      await delete(context, prevContents);
      print('renamed to $newName');
    } catch (err) {
      showAlertDialog(context, 'Error saving file', err.toString());
    }
  }
}
