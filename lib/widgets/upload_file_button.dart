import 'dart:io';

import 'package:Minutes/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';

class UploadFileButton extends StatelessWidget {
  const UploadFileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, UploadFileButtonVM>(
      distinct: true,
      converter: (store) => UploadFileButtonVM(store.state.audio.file,
          store.state.audio.pickFile, store.state.audio.removeSelectedFile),
      builder: (_, viewModel) {
        return PopupMenuButton(
            icon: Icon(
              Icons.file_upload_outlined,
              color: almostWhite,
              size: 30,
            ),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(CupertinoIcons.folder_open),
                        SizedBox(height: 10, width: 10),
                        Text('Choose Files',
                            style: TextStyle(color: Colors.black)),
                      ],
                    ),
                    onTap: () => viewModel.pickFile(fromGallery: false)),
                PopupMenuItem(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(CupertinoIcons.photo_on_rectangle),
                      SizedBox(height: 10, width: 10),
                      Text('Photo Library',
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                  onTap: () => viewModel.pickFile(fromGallery: true),
                )
              ];
            });
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
