import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:share_extend/share_extend.dart';

class AudioPlayerContextMenu extends StatelessWidget {
  const AudioPlayerContextMenu({Key? key}) : super(key: key);

  void shareTranscript(File? file) async {
    ShareExtend.share(file!.path, "file");
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AudioPlayerContextMenuVM>(
      converter: (store) => AudioPlayerContextMenuVM(
          store.state.untitled.file, store.state.untitled.removeSelectedFile),
      builder: (_, viewModel) {
        return CupertinoContextMenu(
          actions: <Widget>[
            CupertinoContextMenuAction(
              trailingIcon: CupertinoIcons.trash,
              child: const Text('Delete Audio'),
              onPressed: () {
                viewModel.removeFile();
                Navigator.of(context).pop();
              },
            ),
            CupertinoContextMenuAction(
              trailingIcon: CupertinoIcons.share,
              child: const Text('Share Audio'),
              onPressed: () {
                shareTranscript(viewModel.file);
                Navigator.of(context).pop();
              },
            ),
          ],
          child: Icon(
            CupertinoIcons.ellipsis,
            color: Color.fromARGB(180, 0, 0, 0),
            size: 30,
          ),
        );
      },
    );
  }
}

class AudioPlayerContextMenuVM {
  File? file;
  void Function() removeFile;
  AudioPlayerContextMenuVM(this.file, this.removeFile);
}
