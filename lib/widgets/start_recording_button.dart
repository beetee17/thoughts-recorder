import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/widgets/widget_with_shadow.dart';

class StartRecordingButton extends StatelessWidget {
  const StartRecordingButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, StartRecordingButtonVM>(
      distinct: true,
      converter: (store) => StartRecordingButtonVM(
          store.state.recorder.startRecording,
          store.state.recorder.pauseRecording,
          store.state.recorder.isRecording),
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
                      ? viewModel.pauseRecording
                      : viewModel.startRecording,
                  iconSize: 50,
                  color: Colors.white,
                  icon: Icon(viewModel.isRecording ? Icons.pause : Icons.mic)),
            ),
          ),
        );
      },
    );
  }
}

class StartRecordingButtonVM {
  void Function() startRecording;
  void Function() pauseRecording;
  bool isRecording;
  StartRecordingButtonVM(
      this.startRecording, this.pauseRecording, this.isRecording);
  @override
  bool operator ==(other) {
    return (other is StartRecordingButtonVM) &&
        (startRecording == other.startRecording) &&
        (pauseRecording == other.pauseRecording) &&
        (isRecording == other.isRecording);
  }

  @override
  int get hashCode {
    return Object.hash(startRecording, pauseRecording, isRecording);
  }
}
