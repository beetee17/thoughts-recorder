import 'package:flutter/material.dart';
import 'package:leopard_demo/main.dart';
import 'package:leopard_demo/providers/audio_file_provider.dart';
import 'package:provider/provider.dart';

import '../providers/main_provider.dart';

class TranscribeAudioFileButton extends StatelessWidget {
  const TranscribeAudioFileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MainProvider mainProvider = context.read<MainProvider>();
    AudioFileProvider audioFile = context.watch<AudioFileProvider>();

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: () => mainProvider.processRecording(audioFile.file!,
            audioLength: audioFile.duration.toDouble() / 1000),
        child: Text("Transcribe File"),
      ),
    );
  }
}
