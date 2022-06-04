import 'package:leopard_demo/redux_/recorder.dart';
import 'package:leopard_demo/redux_/status.dart';
import 'package:leopard_demo/redux_/untitled.dart';
import 'package:redux_dev_tools/redux_dev_tools.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'audio.dart';

// Define your State
class AppState {
  final UntitledState untitled;
  final RecorderState recorder;
  final AudioState audio;
  final StatusState status;
  AppState(this.untitled, this.recorder, this.audio, this.status);

  static AppState empty() {
    return AppState(UntitledState.empty(), RecorderState.empty(),
        AudioState.empty(), StatusState.empty());
  }

  @override
  String toString() {
    return '$untitled \n$recorder \n$audio \n$status';
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
    untitledReducer(state.untitled, action),
    recorderReducer(state.recorder, action),
    audioReducer(state.audio, action),
    statusReducer(state.status, action));

final store = DevToolsStore<AppState>(appStateReducer,
    initialState: AppState.empty(), middleware: [thunkMiddleware]);
