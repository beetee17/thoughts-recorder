import 'dart:io';

import 'package:Minutes/redux_/rootStore.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../utils/save_file_contents.dart';
import '../utils/save_file_handler.dart';
import 'package:redux/redux.dart';

class FilesState {
  final List<SaveFileContents> all;
  FilesState({required this.all});

  static FilesState empty() {
    return FilesState(all: []);
  }

  FilesState copyWith({List<SaveFileContents>? saveFiles}) {
    return FilesState(all: saveFiles ?? this.all);
  }

  @override
  String toString() {
    return '\ntranscripts: $all';
  }

  @override
  bool operator ==(other) {
    return (other is FilesState) && (all == other.all);
  }

  @override
  int get hashCode {
    return all.hashCode;
  }
}

class SaveFilesChangeAction {
  List<SaveFileContents> saveFiles;
  SaveFilesChangeAction(this.saveFiles);
}

ThunkAction<AppState> refreshFiles = (Store<AppState> store) async {
  // Find txt files
  final List<File> files = await SaveFileHandler.appFilesDirectory
      .then((dir) => dir.list().toList().then((entities) {
            return entities
                .whereType<File>()
                .where((file) => file.path.endsWith('.txt'))
                .toList();
          }));

  // Decode files to transcripts

  final List<SaveFileContents?> contents = await Future.wait(files.map((e) {
    return SaveFileHandler.load(e.path);
  }));
  final List<SaveFileContents> finalContents =
      contents.whereType<SaveFileContents>().toList();
  finalContents.sort(((a, b) => b.creationDate.compareTo(a.creationDate)));
  await store.dispatch(SaveFilesChangeAction(finalContents));
};

// Each reducer will handle actions related to the State Tree it cares about!
FilesState filesReducer(FilesState prevState, action) {
  if (action is SaveFilesChangeAction) {
    return prevState.copyWith(saveFiles: action.saveFiles);
  } else {
    return prevState;
  }
}
