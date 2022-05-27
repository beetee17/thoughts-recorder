import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/main_provider.dart';

class StartButton extends StatelessWidget {
  const StartButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MainProvider provider = context.read<MainProvider>();
    bool isRecording = context.watch<MainProvider>().isRecording;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed:
            (isRecording) ? provider.stopRecording : provider.startRecording,
        child: Text(isRecording ? "Stop" : "Start"),
      ),
    );
  }
}
