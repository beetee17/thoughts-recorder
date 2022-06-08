import 'dart:io';
import 'package:Minutes/utils/save_file_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:share_extend/share_extend.dart';

class AudioPlayerContextMenu extends StatelessWidget {
  const AudioPlayerContextMenu({Key? key}) : super(key: key);

  void shareTranscript(File? file) async {
    ShareExtend.share(file!.path, "file");
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AudioPlayerContextMenuVM>(
      distinct: true,
      converter: (store) => AudioPlayerContextMenuVM(
          store.state.audio.file, store.state.audio.removeSelectedFile),
      builder: (_, viewModel) {
        return PopupMenuButton(
            icon: Icon(
              CupertinoIcons.ellipsis,
              color: Color.fromARGB(180, 0, 0, 0),
              size: 30,
            ),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(CupertinoIcons.trash),
                        SizedBox(height: 10, width: 10),
                        Text('Delete Audio'),
                      ],
                    ),
                    onTap: viewModel.removeFile),
                PopupMenuItem(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(CupertinoIcons.share),
                      SizedBox(height: 10, width: 10),
                      Text('Share Audio'),
                    ],
                  ),
                  onTap: () => shareTranscript(viewModel.file),
                ),
              ];
            });
      },
    );
  }
}

class AudioPlayerContextMenuVM {
  File? file;
  void Function() removeFile;
  AudioPlayerContextMenuVM(this.file, this.removeFile);
  @override
  bool operator ==(other) {
    return (other is AudioPlayerContextMenuVM) &&
        (file == other.file) &&
        (removeFile == other.removeFile);
  }

  @override
  int get hashCode {
    return Object.hash(file, removeFile);
  }
}
