import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/redux_/transcriber.dart';
import 'package:Minutes/utils/extensions.dart';

import 'package:leopard_flutter/leopard_error.dart';

import 'package:Minutes/redux_/rootStore.dart';

import 'audio.dart';

class UIState {
  final bool showMinutes;
  UIState({required this.showMinutes});

  static UIState empty() {
    return UIState(showMinutes: true);
  }

  UIState copyWith({
    bool? showMinutes,
  }) {
    return UIState(showMinutes: showMinutes ?? this.showMinutes);
  }

  @override
  String toString() {
    return '\nshowing minutes: $showMinutes';
  }

  @override
  bool operator ==(other) {
    return (other is UIState) && (showMinutes == other.showMinutes);
  }

  @override
  int get hashCode {
    return showMinutes.hashCode;
  }
}

class ToggleMinutesViewAction {}

// Each reducer will handle actions related to the State Tree it cares about!
UIState uiReducer(UIState prevState, action) {
  if (action is ToggleMinutesViewAction) {
    return prevState.copyWith(showMinutes: !prevState.showMinutes);
  } else {
    return prevState;
  }
}
