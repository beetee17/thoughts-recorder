import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:leopard_demo/mic_recorder.dart';
import 'package:leopard_demo/redux_/recorder.dart';
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
  final String? errorMessage;

  final String statusAreaText;

  final List<int> combinedFrame;
  final Duration combinedDuration;

  final List<Pair<String, Duration>> transcriptTextList;
  final int? highlightedSpanIndex;

  String get transcriptText =>
      transcriptTextList.map((p) => p.first).join(' \n\n');

  final Leopard? leopard;

  UntitledState(
      {required this.errorMessage,
      required this.highlightedSpanIndex,
      required this.leopard,
      required this.statusAreaText,
      required this.combinedFrame,
      required this.combinedDuration,
      required this.transcriptTextList});

  static UntitledState empty() {
    return UntitledState(
      combinedDuration: Duration.zero,
      combinedFrame: [],
      errorMessage: null,
      highlightedSpanIndex: null,
      leopard: null,
      statusAreaText: 'No audio file',
      transcriptTextList: [],
    );
  }

  UntitledState copyWith({
    String? errorMessage,
    String? statusAreaText,
    List<int>? combinedFrame,
    Duration? combinedDuration,
    List<Pair<String, Duration>>? transcriptTextList,
    int? highlightedSpanIndex,
    Leopard? leopard,
    bool shouldOverrideError = false,
  }) {
    return UntitledState(
      errorMessage: shouldOverrideError ? errorMessage : this.errorMessage,
      statusAreaText: statusAreaText ?? this.statusAreaText,
      combinedFrame: combinedFrame ?? this.combinedFrame,
      combinedDuration: combinedDuration ?? this.combinedDuration,
      transcriptTextList: transcriptTextList ?? this.transcriptTextList,
      highlightedSpanIndex: highlightedSpanIndex ?? this.highlightedSpanIndex,
      leopard: leopard ?? this.leopard,
    );
  }

  @override
  String toString() {
    return '\nhighlightedIndex:$highlightedSpanIndex\ncombinedDuration: $combinedDuration'
        '\ncombinedFrames: ${combinedFrame.length} frames'
        '\nTranscript: $transcriptTextList';
  }

  @override
  bool operator ==(other) {
    return (other is UntitledState) &&
        (errorMessage == other.errorMessage) &&
        (statusAreaText == other.statusAreaText) &&
        (combinedFrame == other.combinedFrame) &&
        (combinedDuration == other.combinedDuration) &&
        (transcriptTextList == other.transcriptTextList) &&
        (highlightedSpanIndex == other.highlightedSpanIndex) &&
        (leopard == other.leopard);
  }

  @override
  int get hashCode {
    return Object.hash(
      combinedDuration,
      combinedFrame,
      errorMessage,
      highlightedSpanIndex,
      leopard,
      statusAreaText,
      transcriptTextList,
    );
  }

  void highlightSpan(int index) {
    store.dispatch(HighlightSpanAtIndex(index));
  }

  // File Picker Functions
  void pickFile({bool fromGallery = false}) {
    // From SDK Documentation:
    // The file needs to have a sample rate equal to or greater than Leopard.sampleRate.
    // The supported formats are: FLAC, MP3, Ogg, Opus, Vorbis, WAV, and WebM.
    // TODO: Now support any media file type through conversion of file via ffmpeg.
    FilePicker.platform
        .pickFiles(
            type: fromGallery ? FileType.video : FileType.custom,
            allowedExtensions: fromGallery
                ? null
                : [
                    'flac',
                    'mp3',
                    'ogg',
                    'opus',
                    'vorbis',
                    'wav',
                    'webm',
                    'mp4',
                    'mov',
                    'avi'
                  ])
        .then((res) {
      if (res != null) {
        store.dispatch(AudioFileChangeAction(File(res.files.single.path!)));
        store.dispatch(processCurrentAudioFile);
      } else {
        // User canceled the picker
      }
    });
  }

  void removeSelectedFile() {
    store.dispatch(AudioFileChangeAction(null));
  }

  Future<Pair<String, Duration>> processCombined(
      List<int> combinedFrame, Duration startTime) async {
    // TODO: Handle if leopard is somehow not initialised.
    final transcript = await leopard!.process(combinedFrame);
    return Pair(transcript.formatText(), startTime);
  }

  void errorCallback(LeopardException error) {
    store.dispatch(ErrorCallbackAction(error.message ?? error.toString()));
  }
}

// Define your Actions
class InitAction {
  Leopard leopard;
  MicRecorder micRecorder;
  InitAction(this.leopard, this.micRecorder);
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
          leopard.sampleRate, store.state.untitled.errorCallback);
      print('dispatching $leopard and $micRecorder');
      store.dispatch(InitAction(leopard, micRecorder));
    } on LeopardInvalidArgumentException catch (ex) {
      print('ERROR');
      store.state.untitled.errorCallback(LeopardInvalidArgumentException(
          "Invalid Access Key.\n"
          "Please check that the access key entered in the Settings corresponds to "
          "the one in the Picovoice Console (https://console.picovoice.ai/). "));
    } on LeopardActivationException {
      store.state.untitled.errorCallback(
          LeopardActivationException("Access Key activation error."));
    } on LeopardActivationLimitException {
      store.state.untitled.errorCallback(LeopardActivationLimitException(
          "Access Key has reached its device limit."));
    } on LeopardActivationRefusedException {
      store.state.untitled.errorCallback(
          LeopardActivationRefusedException("Access Key was refused."));
    } on LeopardActivationThrottledException {
      store.state.untitled.errorCallback(LeopardActivationThrottledException(
          "Access Key has been throttled."));
    } on LeopardException catch (ex) {
      store.state.untitled.errorCallback(ex);
    }
  }
}

class HighlightSpanAtIndex {
  int index;
  HighlightSpanAtIndex(this.index);
}

class AudioPositionChangeAction {
  Duration newPosition;
  AudioPositionChangeAction(this.newPosition);
}

class ProcessedRemainingFramesAction {
  Pair<String, Duration> remainingTranscript;
  ProcessedRemainingFramesAction(this.remainingTranscript);
}

class StartProcessingAudioFileAction {}

class StatusTextChangeAction {
  String statusText;
  StatusTextChangeAction(this.statusText);
}

class UpdateTranscriptTextList {
  int index;
  Pair<String, Duration> partialTranscript;
  UpdateTranscriptTextList(this.index, this.partialTranscript);
}

class ErrorCallbackAction {
  String errorMessage;
  ErrorCallbackAction(this.errorMessage);
}

class RecordedCallbackAction {
  double recordedLength;
  List<int> recordedFrame;
  RecordedCallbackAction(this.recordedLength, this.recordedFrame);
}

class RecordedCallbackUpdateAction {
  Duration recordedLength;
  List<int> combinedFrame;
  Duration combinedDuration;
  RecordedCallbackUpdateAction(
      this.recordedLength, this.combinedFrame, this.combinedDuration);
}

class IncomingTranscriptAction {
  Pair<String, Duration> transcript;
  IncomingTranscriptAction(this.transcript);
}

ThunkAction<AppState> processRemainingFrames = (Store<AppState> store) async {
  UntitledState state = store.state.untitled;
  RecorderState recorder = store.state.recorder;
  AudioState audio = store.state.audio;

  final remainingFrames = state.combinedFrame;
  remainingFrames.addAll(recorder.micRecorder!.combinedFrame);

  final Duration startTime =
      DurationUtils.max(Duration.zero, audio.duration - state.combinedDuration);
  final remainingTranscript =
      await state.processCombined(state.combinedFrame, startTime);
  if (remainingTranscript.first.trim().isNotEmpty) {
    await store.dispatch(ProcessedRemainingFramesAction(remainingTranscript));
  }
  await store.dispatch(AudioFileChangeAction(audio.file));
};

// Each reducer will handle actions related to the State Tree it cares about!
UntitledState untitledReducer(UntitledState prevState, action) {
  if (action is! AudioPositionChangeAction) {
    print(action);
  }
  if (action is InitAction) {
    return prevState.copyWith(
        leopard: action.leopard, errorMessage: null, shouldOverrideError: true);
  } else if (action is HighlightSpanAtIndex) {
    return prevState.copyWith(highlightedSpanIndex: action.index);
  } else if (action is AudioFileChangeAction) {
    final String? path = action.file?.path;
    final String filename = path == null
        ? 'No audio file'
        : RegExp(r'[^\/]+$').allMatches(action.file!.path).last.group(0)!;
    return prevState.copyWith(statusAreaText: '$filename');
  } else if (action is StartRecordSuccessAction) {
    return prevState.copyWith(
        transcriptTextList: [],
        highlightedSpanIndex: null,
        combinedFrame: [],
        combinedDuration: Duration.zero);
  } else if (action is ProcessedRemainingFramesAction) {
    final newTranscriptTextList = prevState.transcriptTextList;
    newTranscriptTextList.add(action.remainingTranscript);
    return prevState.copyWith(
        transcriptTextList: newTranscriptTextList, highlightedSpanIndex: 0);
  } else if (action is StartProcessingAudioFileAction) {
    return prevState.copyWith(
        transcriptTextList: [],
        highlightedSpanIndex: null,
        combinedFrame: [],
        combinedDuration: Duration.zero);
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
        highlightedSpanIndex: newTranscriptTextList.length - 1,
        combinedFrame: [],
        combinedDuration: Duration.zero);
  } else if (action is RecordedCallbackUpdateAction) {
    return prevState.copyWith(
        combinedFrame: action.combinedFrame,
        combinedDuration: action.combinedDuration);
  } else if (action is ErrorCallbackAction) {
    return prevState.copyWith(
        errorMessage: action.errorMessage, shouldOverrideError: true);
  } else if (action is AudioPositionChangeAction) {
    final int highlightIndex = prevState.transcriptTextList.lastIndexWhere(
        // We do not want the edge cases due to rounding errors
        (pair) => pair.second <= action.newPosition);
    return prevState.copyWith(highlightedSpanIndex: highlightIndex);
  } else if (action is StatusTextChangeAction) {
    return prevState.copyWith(statusAreaText: action.statusText);
  } else {
    return prevState;
  }
}
