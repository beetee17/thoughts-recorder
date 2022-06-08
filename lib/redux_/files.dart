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

  FilesState copyWith({List<SaveFileContents>? transcripts}) {
    return FilesState(all: transcripts ?? this.all);
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

class TranscriptsChangeAction {
  List<SaveFileContents> transcripts;
  TranscriptsChangeAction(this.transcripts);
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
  try {
    final List<SaveFileContents?> transcripts =
        await Future.wait(files.map((e) {
      return SaveFileHandler.load(e.path);
    }));
    await store.dispatch(TranscriptsChangeAction(
        transcripts.whereType<SaveFileContents>().toList()));
  } catch (err) {
    print('Error on loading saved file: $err');
  }
};

// Each reducer will handle actions related to the State Tree it cares about!
FilesState filesReducer(FilesState prevState, action) {
  if (action is TranscriptsChangeAction) {
    return prevState.copyWith(transcripts: action.transcripts);
  } else {
    return prevState;
  }
}
