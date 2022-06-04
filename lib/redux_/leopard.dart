import 'dart:io';

import 'package:leopard_demo/mic_recorder.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:leopard_demo/utils/persistence.dart';

import 'package:leopard_flutter/leopard.dart';
import 'package:leopard_flutter/leopard_error.dart';

import 'package:redux/redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../utils/pair.dart';

class LeopardState {
  final Leopard? instance;

  LeopardState({required this.instance});

  static LeopardState empty() {
    return LeopardState(instance: null);
  }

  LeopardState copyWith({
    Leopard? instance,
  }) {
    return LeopardState(instance: instance ?? this.instance);
  }

  @override
  String toString() {
    return '\nleopard: $instance';
  }

  @override
  bool operator ==(other) {
    return (other is LeopardState) && (instance == other.instance);
  }

  @override
  int get hashCode {
    return instance.hashCode;
  }

  Future<Pair<String, Duration>> processCombined(
      List<int> combinedFrame, Duration startTime) async {
    // TODO: Handle if leopard is somehow not initialised.
    final transcript = await instance!.process(combinedFrame);
    return Pair(transcript.formatText(), startTime);
  }
}

class InitialisationSuccessAction {
  Leopard leopard;
  MicRecorder micRecorder;
  InitialisationSuccessAction(this.leopard, this.micRecorder);
}

// Define your Actions
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

// Each reducer will handle actions related to the State Tree it cares about!
LeopardState leopardReducer(LeopardState prevState, action) {
  if (action is InitialisationSuccessAction) {
    return prevState.copyWith(instance: action.leopard);
  } else {
    return prevState;
  }
}
