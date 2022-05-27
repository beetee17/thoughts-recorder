import 'package:flutter/material.dart';
import 'package:leopard_demo/providers/main_provider.dart';
import 'package:share_extend/share_extend.dart';
import 'package:provider/provider.dart';

class SaveTranscriptButton extends StatelessWidget {
  const SaveTranscriptButton({Key? key}) : super(key: key);

  void shareTranscript(text) async {
    // Directory dir = await getApplicationDocumentsDirectory();
    // File testFile = File("${dir.path}/transcript.txt");

    // await testFile.create(recursive: true);
    // testFile.writeAsStringSync(text);

    ShareExtend.share(text, "text");
  }

  @override
  Widget build(BuildContext context) {
    final String transcriptText = context.watch<MainProvider>().transcriptText;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: () => shareTranscript(transcriptText),
        child: const Text('Share Transcript'),
      ),
    );
  }
}
