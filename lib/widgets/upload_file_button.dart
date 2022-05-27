import 'dart:io';

import 'package:flutter/material.dart';
import 'package:leopard_demo/providers/audio_file_provider.dart';
import 'package:provider/provider.dart';

import '../providers/main_provider.dart';

class UploadFileButton extends StatelessWidget {
  const UploadFileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AudioFileProvider fileProvider = context.watch<AudioFileProvider>();
    File? userSelectedFile = fileProvider.userSelectedFile;
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: userSelectedFile == null
            ? fileProvider.pickFile
            : fileProvider.removeSelectedFile,
        child: userSelectedFile == null
            ? Text('Upload File')
            : Text('Remove File'),
      ),
    );
  }
}
