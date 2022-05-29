import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:provider/provider.dart';

import '../providers/main_provider.dart';

class StartRecordingButton extends StatelessWidget {
  const StartRecordingButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, StartRecordingButtonVM>(
      converter: (store) => StartRecordingButtonVM(
          store.state.untitled.startRecording,
          store.state.untitled.stopRecording,
          store.state.untitled.isRecording),
      builder: (_, viewModel) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton(
            onPressed: (viewModel.isRecording)
                ? viewModel.stopRecording
                : viewModel.startRecording,
            child: Text(viewModel.isRecording ? "Stop" : "Record"),
          ),
        );
      },
    );
  }
}

class StartRecordingButtonVM {
  void Function() startRecording;
  void Function() stopRecording;
  bool isRecording;
  StartRecordingButtonVM(
      this.startRecording, this.stopRecording, this.isRecording);
}
