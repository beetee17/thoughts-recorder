import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:leopard_demo/widgets/audio_player.dart';

class SelectedFile extends StatelessWidget {
  final File? userSelectedFile;

  const SelectedFile({Key? key, required this.userSelectedFile})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userSelectedFile == null) {
      return const Text('No file selected');
    } else {
      return AudioPlayerWidget(audioFile: userSelectedFile!);
      // Text text = Text(userSelectedFile!.path);
      // return Padding(padding: const EdgeInsets.all(16.0), child: text);
    }
  }
}
