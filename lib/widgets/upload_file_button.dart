import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';

class UploadFileButton extends StatelessWidget {
  const UploadFileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, UploadFileButtonVM>(
      converter: (store) => UploadFileButtonVM(
          store.state.untitled.file,
          store.state.untitled.pickFile,
          store.state.untitled.removeSelectedFile),
      builder: (_, viewModel) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton(
            onPressed: viewModel.file == null
                ? viewModel.pickFile
                : viewModel.removeFile,
            child: viewModel.file == null
                ? Text('Upload Audio')
                : Text('Remove Audio'),
          ),
        );
      },
    );
  }
}

class UploadFileButtonVM {
  File? file;
  void Function() pickFile;
  void Function() removeFile;
  UploadFileButtonVM(this.file, this.pickFile, this.removeFile);
}
