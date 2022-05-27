import 'dart:io';

import 'package:flutter/material.dart';
import 'package:leopard_demo/providers/audio_file_provider.dart';
import 'package:provider/provider.dart';

import '../providers/main_provider.dart';

class UploadFileButton extends StatelessWidget {
  const UploadFileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MainProvider provider = context.watch<MainProvider>();
    File? userSelectedFile = provider.file;
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: userSelectedFile == null
            ? provider.pickFile
            : provider.removeSelectedFile,
        child: userSelectedFile == null
            ? Text('Upload Audio')
            : Text('Remove Audio'),
      ),
    );
  }
}
