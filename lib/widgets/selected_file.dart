import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/widgets/start_recording_button.dart';
import 'package:leopard_demo/widgets/upload_file_button.dart';

import 'just_audio_player.dart';

class SelectedFile extends StatelessWidget {
  const SelectedFile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, SelectedFileVM>(
        converter: (store) => SelectedFileVM(store.state.untitled.file),
        builder: (_, viewModel) {
          return Container(
              child: viewModel.file == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Spacer(),
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
  SelectedFileVM(this.file);
  @override
  bool operator ==(other) {
    return (other is SelectedFileVM) && (file == other.file);
  }

  @override
  int get hashCode {
    return file.hashCode;
  }
}
