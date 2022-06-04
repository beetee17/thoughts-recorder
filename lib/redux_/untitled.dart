import 'dart:io';

import 'package:leopard_demo/mic_recorder.dart';
import 'package:leopard_demo/redux_/recorder.dart';
import 'package:leopard_demo/redux_/transcript.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:leopard_demo/utils/persistence.dart';

import 'package:leopard_flutter/leopard.dart';
import 'package:leopard_flutter/leopard_error.dart';

import 'package:redux/redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../utils/pair.dart';
import 'audio.dart';

// Define your State
class UntitledState {
  final List<int> combinedFrame;
  final Duration combinedDuration;

  final Leopard? leopard;

  UntitledState(
      {required this.leopard,
      required this.combinedFrame,
      required this.combinedDuration});

  static UntitledState empty() {
    return UntitledState(
      combinedDuration: Duration.zero,
      combinedFrame: [],
      leopard: null,
    );
  }

  UntitledState copyWith({
    List<int>? combinedFrame,
    Duration? combinedDuration,
    Leopard? leopard,
  }) {
    return UntitledState(
      combinedFrame: combinedFrame ?? this.combinedFrame,
      combinedDuration: combinedDuration ?? this.combinedDuration,
      leopard: leopard ?? this.leopard,
    );
  }

  @override
  String toString() {
    return '\ncombinedDuration: $combinedDuration'
        '\ncombinedFrames: ${combinedFrame.length} frames';
  }

  @override
  bool operator ==(other) {
    return (other is UntitledState) &&
        (combinedFrame == other.combinedFrame) &&
        (combinedDuration == other.combinedDuration) &&
        (leopard == other.leopard);
  }

  @override
  int get hashCode {
    return Object.hash(
      combinedDuration,
      combinedFrame,
      leopard,
    );
  }

  Future<Pair<String, Duration>> processCombined(
      List<int> combinedFrame, Duration startTime) async {
    // TODO: Handle if leopard is somehow not initialised.
    final transcript = await leopard!.process(combinedFrame);
    return Pair(transcript.formatText(), startTime);
  }
}

// Define your Actions
class InitialisationSuccessAction {
  Leopard leopard;
  MicRecorder micRecorder;
  InitialisationSuccessAction(this.leopard, this.micRecorder);
}

class InitLeopardAction implements CallableThunkAction<AppState> {
  @override
  Future<void> call(Store<AppState> store) async {
    String platform = Platform.isAndroid
        ? "android"
        : Platform.isIOS
            ? "ios"
            : throw LeopardRuntimeException(
                "This demo supports iOS and Android only.");
    String modelPath = "assets/models/ios/myModel-leopard.pv";

    try {
      final accessKey = await Settings.getAccessKey();
      final leopard = await Leopard.create(accessKey, modelPath);
      final micRecorder = await MicRecorder.create(
          leopard.sampleRate, store.state.status.errorCallback);
      print('dispatching $leopard and $micRecorder');
      store.dispatch(InitialisationSuccessAction(leopard, micRecorder));
    } on LeopardInvalidArgumentException catch (ex) {
      print('ERROR');
      store.state.status.errorCallback(LeopardInvalidArgumentException(
          "Invalid Access Key.\n"
          "Please check that the access key entered in the Settings corresponds to "
          "the one in the Picovoice Console (https://console.picovoice.ai/). "));
    } on LeopardActivationException {
      store.state.status.errorCallback(
          LeopardActivationException("Access Key activation error."));
    } on LeopardActivationLimitException {
      store.state.status.errorCallback(LeopardActivationLimitException(
          "Access Key has reached its device limit."));
    } on LeopardActivationRefusedException {
      store.state.status.errorCallback(
          LeopardActivationRefusedException("Access Key was refused."));
    } on LeopardActivationThrottledException {
      store.state.status.errorCallback(LeopardActivationThrottledException(
          "Access Key has been throttled."));
    } on LeopardException catch (ex) {
      store.state.status.errorCallback(ex);
    }
  }
}

class StartProcessingAudioFileAction {}

// Each reducer will handle actions related to the State Tree it cares about!
UntitledState untitledReducer(UntitledState prevState, action) {
  if (action is! AudioPositionChangeAction) {
    print(action);
  }
  if (action is InitialisationSuccessAction) {
    return prevState.copyWith(leopard: action.leopard);
  } else if (action is StartRecordSuccessAction) {
    return prevState
        .copyWith(combinedFrame: [], combinedDuration: Duration.zero);
  } else if (action is StartProcessingAudioFileAction) {
    return prevState
        .copyWith(combinedFrame: [], combinedDuration: Duration.zero);
  } else if (action is IncomingTranscriptAction) {
    return prevState
        .copyWith(combinedFrame: [], combinedDuration: Duration.zero);
  } else if (action is RecordedCallbackUpdateAction) {
    return prevState.copyWith(
        combinedFrame: action.combinedFrame,
        combinedDuration: action.combinedDuration);
  } else {
    return prevState;
  }
}
