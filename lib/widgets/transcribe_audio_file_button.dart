import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/redux_/untitled.dart';

class TranscribeAudioFileButton extends StatelessWidget {
  const TranscribeAudioFileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, TranscribeAudioFileButtonVM>(
      converter: (store) => TranscribeAudioFileButtonVM(
          store.state.audio.duration, store.state.untitled),
      builder: (_, viewModel) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton(
            onPressed: () => store.dispatch(processCurrentAudioFile),
            child: Text("Transcribe"),
          ),
        );
      },
    );
  }
}

class TranscribeAudioFileButtonVM {
  int audioFileDuration;
  UntitledState state;
  TranscribeAudioFileButtonVM(this.audioFileDuration, this.state);
  @override
  bool operator ==(other) {
    return (other is TranscribeAudioFileButtonVM) &&
        (audioFileDuration == other.audioFileDuration) &&
        (state == other.state);
  }

  @override
  int get hashCode {
    return Object.hash(audioFileDuration, state);
  }
}
