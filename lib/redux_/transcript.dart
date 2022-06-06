import 'package:Minutes/redux_/leopard.dart';
import 'package:Minutes/redux_/recorder.dart';
import 'package:Minutes/redux_/transcriber.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/transcriptClasses.dart';

import 'package:redux/redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'audio.dart';

class TranscriptState {
  final List<TranscriptPair> transcriptTextList;
  final int? highlightedSpanIndex;

  String get transcriptText =>
      transcriptTextList.map((p) => p.text).join(' \n\n');
  TranscriptState(
      {required this.highlightedSpanIndex, required this.transcriptTextList});

  static TranscriptState empty() {
    return TranscriptState(
      highlightedSpanIndex: null,
      transcriptTextList: [],
    );
  }

  TranscriptState copyWith({
    List<TranscriptPair>? transcriptTextList,
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
  TranscriptPair transcript;
  IncomingTranscriptAction(this.transcript);
}

class UpdateTranscriptTextList {
  int index;
  TranscriptPair partialTranscript;
  UpdateTranscriptTextList(this.index, this.partialTranscript);
}

class ProcessedRemainingFramesAction {
  TranscriptPair remainingTranscript;
  ProcessedRemainingFramesAction(this.remainingTranscript);
}

ThunkAction<AppState> processRemainingFrames = (Store<AppState> store) async {
  TranscriberState state = store.state.transcriber;
  LeopardState leopard = store.state.leopard;
  RecorderState recorder = store.state.recorder;
  AudioState audio = store.state.audio;

  final remainingFrames = state.combinedFrame;
  remainingFrames.addAll(recorder.micRecorder!.combinedFrame);

  final Duration startTime =
      DurationUtils.max(Duration.zero, audio.duration - state.combinedDuration);
  final remainingTranscript =
      await leopard.processCombined(state.combinedFrame, startTime);
  if (remainingTranscript.text.trim().isNotEmpty) {
    await store.dispatch(ProcessedRemainingFramesAction(remainingTranscript));
  }
  await store.dispatch(AudioFileChangeAction(audio.file));
};

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
        (pair) => pair.startTime <= action.newPosition);
    return prevState.copyWith(highlightedSpanIndex: highlightIndex);
  } else {
    return prevState;
  }
}
