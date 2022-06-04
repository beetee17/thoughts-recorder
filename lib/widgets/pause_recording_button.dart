import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/widgets/widget_with_shadow.dart';

class PauseRecordingButton extends StatelessWidget {
  const PauseRecordingButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, PauseRecordingButtonVM>(
      distinct: true,
      converter: (store) =>
          PauseRecordingButtonVM(store.state.recorder.pauseRecording),
      builder: (_, viewModel) {
        return IconButton(
            onPressed: viewModel.pauseRecording,
            iconSize: 50,
            color: Colors.black,
            icon: Icon(Icons.pause));
      },
    );
  }
}

class PauseRecordingButtonVM {
  void Function() pauseRecording;
  PauseRecordingButtonVM(this.pauseRecording);
  @override
  bool operator ==(other) {
    return (other is PauseRecordingButtonVM) &&
        (pauseRecording == other.pauseRecording);
  }

  @override
  int get hashCode {
    return pauseRecording.hashCode;
  }
}
