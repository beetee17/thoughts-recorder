import 'dart:io';

import 'package:Minutes/mic_recorder.dart';
import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/persistence.dart';
import 'package:cheetah_flutter/cheetah.dart';

import 'package:leopard_flutter/leopard.dart';
import 'package:leopard_flutter/leopard_error.dart';

import 'package:redux/redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../utils/transcript_pair.dart';

class CheetahState {
  final Cheetah? instance;

  CheetahState({required this.instance});

  static CheetahState empty() {
    return CheetahState(instance: null);
  }

  CheetahState copyWith({
    Cheetah? instance,
  }) {
    return CheetahState(instance: instance ?? this.instance);
  }

  @override
  String toString() {
    return '\nleopard: $instance';
  }

  @override
  bool operator ==(other) {
    return (other is CheetahState) && (instance == other.instance);
  }

  @override
  int get hashCode {
    return instance.hashCode;
  }
}

// Each reducer will handle actions related to the State Tree it cares about!
CheetahState cheetahReducer(CheetahState prevState, action) {
  if (action is InitialisationSuccessAction) {
    return prevState.copyWith(instance: action.cheetah);
  } else {
    return prevState;
  }
}
