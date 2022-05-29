import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/providers/main_provider.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:share_extend/share_extend.dart';
import 'package:provider/provider.dart';

class SaveAudioButton extends StatelessWidget {
  const SaveAudioButton({Key? key}) : super(key: key);

  void saveAudioFile(File? file) async {
    if (file == null) {
      return;
    }
    ShareExtend.share(file.path, "file");
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, SaveAudioButtonVM>(
        converter: (store) => SaveAudioButtonVM(store.state.untitled.file),
        builder: (_, viewModel) {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton(
              onPressed: () => saveAudioFile(viewModel.file),
              child: const Text('Share'),
            ),
          );
        });
  }
}

class SaveAudioButtonVM {
  File? file;
  SaveAudioButtonVM(this.file);
}
