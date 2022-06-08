import 'dart:io';

import 'package:Minutes/redux_/rootStore.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../utils/transcriptClasses.dart';
import 'package:redux/redux.dart';

class FilesState {
  final List<Transcript> transcripts;
  FilesState({required this.transcripts});

  static FilesState empty() {
    return FilesState(transcripts: []);
  }

  FilesState copyWith({List<Transcript>? transcripts}) {
    return FilesState(transcripts: transcripts ?? this.transcripts);
  }

  @override
  String toString() {
    return '\ntranscripts: $transcripts';
  }

  @override
  bool operator ==(other) {
    return (other is FilesState) && (transcripts == other.transcripts);
  }

  @override
  int get hashCode {
    return transcripts.hashCode;
  }
}

class TranscriptsChangeAction {
  List<Transcript> transcripts;
  TranscriptsChangeAction(this.transcripts);
}

ThunkAction<AppState> refreshFiles = (Store<AppState> store) async {
  // Find txt files
  final List<File> files = await TranscriptFileHandler.appFilesDirectory
      .then((dir) => dir.list().toList().then((entities) {
            return entities
                .whereType<File>()
                .where((file) => file.path.endsWith('.txt'))
                .toList();
          }));

  // Decode files to transcripts
  final List<Transcript> transcripts = await Future.wait(files.map((e) {
    return TranscriptFileHandler.load(e.path);
  }));

  await store.dispatch(TranscriptsChangeAction(transcripts));
};

// Each reducer will handle actions related to the State Tree it cares about!
FilesState filesReducer(FilesState prevState, action) {
  if (action is TranscriptsChangeAction) {
    return prevState.copyWith(transcripts: action.transcripts);
  } else {
    return prevState;
  }
}
