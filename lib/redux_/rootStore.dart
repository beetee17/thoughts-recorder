import 'package:leopard_demo/redux_/audio.dart';
import 'package:leopard_demo/redux_/untitled.dart';
import 'package:redux_dev_tools/redux_dev_tools.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Define your State
class AppState {
  final AudioState audio;
  final UntitledState untitled;

  AppState(this.audio, this.untitled);

  static AppState empty() {
    return AppState(AudioState.empty(), UntitledState.empty());
  }

  @override
  String toString() {
    return '$untitled \n$audio';
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
    audioReducer(state.audio, action), untitledReducer(state.untitled, action));

final store = DevToolsStore<AppState>(appStateReducer,
    initialState: AppState.empty(), middleware: [thunkMiddleware]);
