import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';

class TranscribeAudioFileButton extends StatelessWidget {
  const TranscribeAudioFileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, TranscribeAudioFileButtonVM>(
      converter: (store) => TranscribeAudioFileButtonVM(
          store.state.audio.duration,
          store.state.untitled.processCurrentAudioFile),
      builder: (_, viewModel) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton(
            onPressed: () => viewModel.processAudioFile(
                viewModel.audioFileDuration.toDouble() / 1000),
            child: Text("Transcribe"),
          ),
        );
      },
    );
  }
}

class TranscribeAudioFileButtonVM {
  int audioFileDuration;
  void Function(double) processAudioFile;
  TranscribeAudioFileButtonVM(this.audioFileDuration, this.processAudioFile);
}
