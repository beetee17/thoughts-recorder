import 'dart:convert';
import 'dart:io';

import 'package:Minutes/utils/alert_dialog.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/save_file_contents.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:path/path.dart' as path;

class SaveFileHandler {
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

                    SaveFileContents newContents = SaveFileContents(newAudio,
                        fileContents.transcript, fileContents.creationDate);

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

      print('Saving file to $saveFilePath');

      final File saveFile = await File(saveFilePath).create(recursive: true);

      // Copy audio file to app documents
      final String audioFilePath =
          path.join(dir.path, filename + fileContents.audio.extension);

      print('Created file at path, copying audio...');

      final newContents = SaveFileContents(
          await fileContents.audio.copy(audioFilePath),
          fileContents.transcript,
          fileContents.creationDate);

      print('Got new contents $newContents');

      await saveFile.writeAsString(jsonEncode(newContents));

      print('saved to $saveFilePath');
    } catch (err) {
      showAlertDialog(context, 'Error saving file', err.toString());
    }
  }

  static Future<SaveFileContents?> load(String path) async {
    try {
      final String saveFile = await File(path).readAsString();
      print('Loaded $path successfully');
      final Map<String, dynamic> decodedFile = jsonDecode(saveFile);
      print('Decoded $path as: $decodedFile');
      return SaveFileContents.fromJson(decodedFile);
    } catch (err) {
      print("Error loading saved file $path: $err");
      return null;
    }
  }

  static Future<void> delete(
      BuildContext context, SaveFileContents? saveFile) async {
    if (saveFile == null) {
      return;
    }
    try {
      final Directory dir = await appFilesDirectory;
      final String saveFilePath =
          path.join(dir.path, '${saveFile.audio.nameWithoutExtension}.txt');

      saveFile.audio.delete().then((_) => File(saveFilePath).delete());
    } catch (err) {
      showAlertDialog(context, 'Error deleting file', err.toString());
    }
  }

  static Future<void> rename(
      BuildContext context, SaveFileContents? prevContents, String newName,
      {bool force = false}) async {
    if (prevContents == null ||
        prevContents.audio.nameWithoutExtension == newName) {
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
          prevContents.transcript,
          prevContents.creationDate);

      await saveFile.writeAsString(jsonEncode(newContents));
      await delete(context, prevContents);
      print('renamed to $newName');
    } catch (err) {
      showAlertDialog(context, 'Error saving file', err.toString());
    }
  }
}
