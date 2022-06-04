import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:leopard_demo/mic_recorder.dart';
import 'package:leopard_demo/redux_/recorder.dart';
import 'package:leopard_demo/redux_/untitled.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:leopard_demo/utils/persistence.dart';

import 'package:leopard_flutter/leopard.dart';
import 'package:leopard_flutter/leopard_error.dart';

import 'package:redux/redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../utils/pair.dart';
import 'audio.dart';

class TranscriptState {
  final List<Pair<String, Duration>> transcriptTextList;
  final int? highlightedSpanIndex;

  String get transcriptText =>
      transcriptTextList.map((p) => p.first).join(' \n\n');
  TranscriptState(
      {required this.highlightedSpanIndex, required this.transcriptTextList});

  static TranscriptState empty() {
    return TranscriptState(
      highlightedSpanIndex: null,
      transcriptTextList: [],
    );
  }

  TranscriptState copyWith({
    List<Pair<String, Duration>>? transcriptTextList,
    int? highlightedSpanIndex,
  }) {
    return TranscriptState(
      transcriptTextList: transcriptTextList ?? this.transcriptTextList,
      highlightedSpanIndex: highlightedSpanIndex ?? this.highlightedSpanIndex,
    );
  }

  @override
  String toString() {
    return '\nhighlightedIndex:$highlightedSpanIndex'
        '\nTranscript: $transcriptTextList';
  }

  @override
  bool operator ==(other) {
    return (other is TranscriptState) &&
        (transcriptTextList == other.transcriptTextList) &&
        (highlightedSpanIndex == other.highlightedSpanIndex);
  }

  @override
  int get hashCode {
    return Object.hash(
      highlightedSpanIndex,
      transcriptTextList,
    );
  }

  void highlightSpan(int index) {
    store.dispatch(HighlightSpanAtIndex(index));
  }
}

class HighlightSpanAtIndex {
  int index;
  HighlightSpanAtIndex(this.index);
}

class IncomingTranscriptAction {
  Pair<String, Duration> transcript;
  IncomingTranscriptAction(this.transcript);
}

class UpdateTranscriptTextList {
  int index;
  Pair<String, Duration> partialTranscript;
  UpdateTranscriptTextList(this.index, this.partialTranscript);
}

// Each reducer will handle actions related to the State Tree it cares about!
TranscriptState transcriptReducer(TranscriptState prevState, action) {
  if (action is HighlightSpanAtIndex) {
    return prevState.copyWith(highlightedSpanIndex: action.index);
  } else if (action is StartRecordSuccessAction) {
    return prevState
        .copyWith(transcriptTextList: [], highlightedSpanIndex: null);
  } else if (action is ProcessedRemainingFramesAction) {
    final newTranscriptTextList = prevState.transcriptTextList;
    newTranscriptTextList.add(action.remainingTranscript);
    return prevState.copyWith(
        transcriptTextList: newTranscriptTextList, highlightedSpanIndex: 0);
  } else if (action is StartProcessingAudioFileAction) {
    return prevState
        .copyWith(transcriptTextList: [], highlightedSpanIndex: null);
  } else if (action is UpdateTranscriptTextList) {
    final newList = prevState.transcriptTextList;
    newList[action.index] = action.partialTranscript
        .map((text) => text.formatText(), (startTime) => startTime);
    return prevState.copyWith(transcriptTextList: newList);
  } else if (action is IncomingTranscriptAction) {
    final newTranscriptTextList = prevState.transcriptTextList;
    newTranscriptTextList.add(action.transcript);
    return prevState.copyWith(
        transcriptTextList: newTranscriptTextList,
        highlightedSpanIndex: newTranscriptTextList.length - 1);
  } else if (action is AudioPositionChangeAction) {
    final int highlightIndex = prevState.transcriptTextList.lastIndexWhere(
        // We do not want the edge cases due to rounding errors
        (pair) => pair.second <= action.newPosition);
    return prevState.copyWith(highlightedSpanIndex: highlightIndex);
  } else {
    return prevState;
  }
}
