import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/main_provider.dart';

class UploadFileButton extends StatelessWidget {
  const UploadFileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    File? userSelectedFile = context.read<MainProvider>().userSelectedFile;
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: userSelectedFile == null
            ? context.read<MainProvider>().pickFile
            : context.read<MainProvider>().removeSelectedFile,
        child: userSelectedFile == null
            ? Text('Upload File')
            : Text('Remove File'),
      ),
    );
  }
}
