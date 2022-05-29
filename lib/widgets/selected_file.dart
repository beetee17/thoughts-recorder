import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/providers/audio_file_provider.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/widgets/audio_player.dart';
import 'package:provider/provider.dart';

import '../providers/main_provider.dart';

class SelectedFile extends StatelessWidget {
  const SelectedFile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, SelectedFileVM>(
        converter: (store) => SelectedFileVM(store.state.untitled.file),
        builder: (_, viewModel) {
          return Container(
              child: viewModel.file == null
                  ? const Text('No file selected')
                  : AudioPlayerWidget()
              // Text text = Text(userSelectedFile!.path);
              // return Padding(padding: const EdgeInsets.all(16.0), child: text);
              );
        });
  }
}

class SelectedFileVM {
  File? file;
  SelectedFileVM(this.file);
}
