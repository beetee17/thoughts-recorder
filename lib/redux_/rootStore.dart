import 'package:Minutes/redux_/files.dart';
import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/redux_/recorder.dart';
import 'package:Minutes/redux_/status.dart';
import 'package:Minutes/redux_/transcript.dart';
import 'package:Minutes/redux_/transcriber.dart';
import 'package:Minutes/redux_/ui.dart';
import 'package:redux_dev_tools/redux_dev_tools.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:redux/redux.dart';
import 'audio.dart';

// Define your State
class AppState {
  final RecorderState recorder;
  final LeopardState leopard;
  final StatusState status;
  final AudioState audio;
  final TranscriberState transcriber;
  final TranscriptState transcript;
  final FilesState files;
  final UIState ui;

  AppState(this.transcriber, this.recorder, this.audio, this.status,
      this.transcript, this.leopard, this.files, this.ui);

  static AppState empty() {
    return AppState(
        TranscriberState.empty(),
        RecorderState.empty(),
        AudioState.empty(),
        StatusState.empty(),
        TranscriptState.empty(),
        LeopardState.empty(),
        FilesState.empty(),
        UIState.empty());
  }

  @override
  String toString() {
    return '$transcriber \n$recorder \n$audio \n$status \n$transcript \n$files \n$ui';
  }
}

class ClearAllAction implements CallableThunkAction<AppState> {
  @override
  Future<void> call(Store<AppState> store) async {
    await store.dispatch(AudioFileChangeAction(null));
    await store.dispatch(SetTranscriptListAction([]));
  }
}

// Put em together. In this case, we'll create a new app state every time an action
// is dispatched (remember, this should be a pure function!), but we'll use our
// smaller reducer functions instead.
//
// Since our `AppState` constructor has two parameters: `items` and `searchQuery`,
// and our reducers return these types of values, we can simply call those reducer
// functions with the part of the State tree they care about and the current action.
//
// Each reducer will take in the part of the state tree they care about and the
// current action, and return the new list of items or a new search query for
// the constructor!
AppState appStateReducer(AppState state, action) => AppState(
    transcriberReducer(state.transcriber, action),
    recorderReducer(state.recorder, action),
    audioReducer(state.audio, action),
    statusReducer(state.status, action),
    transcriptReducer(state.transcript, action),
    leopardReducer(state.leopard, action),
    filesReducer(state.files, action),
    uiReducer(state.ui, action));

final store = DevToolsStore<AppState>(appStateReducer,
    initialState: AppState.empty(), middleware: [thunkMiddleware]);
