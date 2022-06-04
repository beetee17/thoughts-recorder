import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';

class UploadFileButton extends StatelessWidget {
  const UploadFileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, UploadFileButtonVM>(
      distinct: true,
      converter: (store) => UploadFileButtonVM(
          store.state.audio.file,
          store.state.untitled.pickFile,
          store.state.untitled.removeSelectedFile),
      builder: (_, viewModel) {
        return CupertinoContextMenu(
          actions: <Widget>[
            CupertinoContextMenuAction(
              trailingIcon: CupertinoIcons.folder_open,
              child: const Text('Choose Files'),
              onPressed: () {
                viewModel.pickFile(fromGallery: false);
                Navigator.of(context).pop();
              },
            ),
            CupertinoContextMenuAction(
              trailingIcon: CupertinoIcons.photo_on_rectangle,
              child: const Text('Photo Library'),
              onPressed: () {
                viewModel.pickFile(fromGallery: true);
                Navigator.of(context).pop();
              },
            ),
          ],
          child: Icon(
            Icons.file_upload_outlined,
            color: Color.fromARGB(180, 0, 0, 0),
            size: 30,
          ),
        );
      },
    );
  }
}

class UploadFileButtonVM {
  File? file;
  void Function({bool fromGallery}) pickFile;
  void Function() removeFile;
  UploadFileButtonVM(this.file, this.pickFile, this.removeFile);
  @override
  bool operator ==(other) {
    return (other is UploadFileButtonVM) &&
        (file == other.file) &&
        (pickFile == other.pickFile) &&
        (removeFile == other.removeFile);
  }

  @override
  int get hashCode {
    return Object.hash(file.hashCode, pickFile.hashCode, removeFile.hashCode);
  }
}
