import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_extend/share_extend.dart';

class SaveTranscriptButton extends StatelessWidget {
  final String transcriptText;
  const SaveTranscriptButton({Key? key, required this.transcriptText})
      : super(key: key);

  void shareTranscript() async {
    // Directory dir = await getApplicationDocumentsDirectory();
    // File testFile = File("${dir.path}/transcript.txt");

    // await testFile.create(recursive: true);
    // testFile.writeAsStringSync(transcriptText);

    ShareExtend.share(transcriptText, "text");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: shareTranscript,
        child: const Text('Share Transcript'),
      ),
    );
  }
}
