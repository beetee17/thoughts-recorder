import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/widgets/icon_button_with_shadow.dart';

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
          child: Container(
            decoration: BoxDecoration(
                color: Colors.redAccent.shade400,
                borderRadius: BorderRadius.all(Radius.circular(
                        25.0) //                 <--- border radius here
                    )),
            child: WithShadow(
              child: IconButton(
                  onPressed: (viewModel.isRecording)
                      ? viewModel.stopRecording
                      : viewModel.startRecording,
                  iconSize: 50,
                  color: Colors.white,
                  icon: Icon(viewModel.isRecording ? Icons.stop : Icons.mic)),
            ),
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
