import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/widgets/pause_recording_button.dart';
import 'package:Minutes/widgets/start_recording_button.dart';
import 'package:Minutes/widgets/upload_file_button.dart';

import 'just_audio_player.dart';

class SelectedFile extends StatelessWidget {
  const SelectedFile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, SelectedFileVM>(
        distinct: true,
        converter: (store) => SelectedFileVM(
            store.state.audio.file, store.state.recorder.isRecording),
        builder: (_, viewModel) {
          return Container(
              child: viewModel.file == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        viewModel.isRecording
                            ? Expanded(child: PauseRecordingButton())
                            : Spacer(),
                        StartRecordingButton(),
                        Expanded(child: UploadFileButton())
                      ],
                    )
                  : JustAudioPlayerWidget(file: viewModel.file!));
        });
  }
}

class SelectedFileVM {
  File? file;
  bool isRecording;
  SelectedFileVM(this.file, this.isRecording);

  @override
  bool operator ==(other) {
    return (other is SelectedFileVM) &&
        (file == other.file) &&
        (isRecording == other.isRecording);
    ;
  }

  @override
  int get hashCode {
    return Object.hash(file, isRecording);
  }
}
