import 'dart:io';

import 'package:flutter/material.dart';
import 'package:leopard_demo/providers/audio_file_provider.dart';
import 'package:leopard_demo/widgets/audio_player.dart';
import 'package:provider/provider.dart';

import '../providers/main_provider.dart';

class SelectedFile extends StatelessWidget {
  const SelectedFile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    File? userSelectedFile = context.watch<MainProvider>().file;
    print(userSelectedFile);
    if (userSelectedFile == null) {
      return const Text('No file selected');
    } else {
      return AudioPlayerWidget();
      // Text text = Text(userSelectedFile!.path);
      // return Padding(padding: const EdgeInsets.all(16.0), child: text);
    }
  }
}
