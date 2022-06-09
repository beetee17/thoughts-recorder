import 'dart:io';

import 'package:Minutes/redux_/recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/widgets/start_recording_button.dart';
import 'package:Minutes/widgets/upload_file_button.dart';

import 'just_audio_player.dart';

class SelectedFile extends StatelessWidget {
  const SelectedFile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, SelectedFileVM>(
        distinct: true,
        converter: (store) =>
            SelectedFileVM(store.state.audio.file, store.state.recorder),
        builder: (_, viewModel) {
          return Container(
              child: viewModel.file == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        viewModel.recorder.finishedRecording
                            ? Spacer()
                            : Expanded(
                                child: TextButton(
                                child: Text('Cancel'),
                                onPressed: () =>
                                    viewModel.recorder.cancelRecording(),
                              )),
                        StartRecordingButton(),
                        Expanded(
                            child: viewModel.recorder.finishedRecording
                                ? UploadFileButton()
                                : TextButton(
                                    child: Text('Save'),
                                    onPressed: () =>
                                        viewModel.recorder.stopRecording(),
                                  ))
                      ],
                    )
                  : JustAudioPlayerWidget(file: viewModel.file!));
        });
  }
}

class SelectedFileVM {
  File? file;
  RecorderState recorder;
  SelectedFileVM(this.file, this.recorder);

  @override
  bool operator ==(other) {
    return (other is SelectedFileVM) &&
        (file == other.file) &&
        (recorder == other.recorder);
  }

  @override
  int get hashCode {
    return Object.hash(file, recorder);
  }
}
