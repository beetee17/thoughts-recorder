import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/redux_/recorder.dart';
import 'package:Minutes/redux_/transcriber.dart';
import 'package:Minutes/utils/extensions.dart';

import 'package:leopard_flutter/leopard_error.dart';

import 'package:Minutes/redux_/rootStore.dart';

import 'audio.dart';

class StatusState {
  final String? errorMessage;

  final String statusAreaText;
  StatusState({required this.errorMessage, required this.statusAreaText});

  static StatusState empty() {
    return StatusState(errorMessage: null, statusAreaText: 'No audio file');
  }

  StatusState copyWith({
    String? errorMessage,
    String? statusAreaText,
    bool shouldOverrideError = false,
  }) {
    return StatusState(
      errorMessage: shouldOverrideError ? errorMessage : this.errorMessage,
      statusAreaText: statusAreaText ?? this.statusAreaText,
    );
  }

  @override
  String toString() {
    return '\nerror: $errorMessage \nstatus: $statusAreaText';
  }

  @override
  bool operator ==(other) {
    return (other is StatusState) &&
        (errorMessage == other.errorMessage) &&
        (statusAreaText == other.statusAreaText);
  }

  @override
  int get hashCode {
    return Object.hash(errorMessage, statusAreaText);
  }

  void errorCallback(LeopardException error) {
    store.dispatch(ErrorCallbackAction(error.message ?? error.toString()));
  }
}

class StatusTextChangeAction {
  String statusText;
  StatusTextChangeAction(this.statusText);
}

class ErrorCallbackAction {
  String errorMessage;
  ErrorCallbackAction(this.errorMessage);
}

// Each reducer will handle actions related to the State Tree it cares about!
StatusState statusReducer(StatusState prevState, action) {
  if (action is InitialisationSuccessAction) {
    return prevState.copyWith(errorMessage: null, shouldOverrideError: true);
  } else if (action is AudioFileChangeAction) {
    final String? path = action.file?.path;
    final String filename =
        action.file == null ? 'No audio file' : action.file!.name;
    return prevState.copyWith(statusAreaText: '$filename');
  } else if (action is CancelRecordSuccessAction) {
    return prevState.copyWith(statusAreaText: 'No audio file');
  } else if (action is ErrorCallbackAction) {
    return prevState.copyWith(
        errorMessage: action.errorMessage, shouldOverrideError: true);
  } else if (action is StatusTextChangeAction) {
    return prevState.copyWith(statusAreaText: action.statusText);
  } else {
    return prevState;
  }
}
