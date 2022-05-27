import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leopard_demo/providers/audio_file_provider.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:provider/provider.dart';

import '../providers/main_provider.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({Key? key}) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  @override
  void initState() {
    super.initState();
    context.read<AudioFileProvider>().initialisePlayer();
  }

  @override
  Widget build(BuildContext context) {
    AudioFileProvider audio = context.watch<AudioFileProvider>();

    return Container(
        child: Column(
      children: [
        Container(
          child: Text(
            audio.currentPosLabel,
            style: TextStyle(fontSize: 25),
          ),
        ),
        Container(
            child: Slider(
          value: double.parse(audio.currentPos.toString()),
          min: 0,
          max: double.parse(audio.duration.toString()),
          divisions: audio.duration,
          label: audio.currentPosLabel,
          onChanged: audio.seek,
        )),
        Container(
          child: Wrap(
            spacing: 10,
            children: [
              ElevatedButton.icon(
                  onPressed: audio.togglePlayPause,
                  icon: Icon(audio.isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(audio.isPlaying ? "Pause" : "Play")),
              ElevatedButton.icon(
                  onPressed: audio.stopPlayer,
                  icon: Icon(Icons.stop),
                  label: Text("Stop")),
            ],
          ),
        )
      ],
    ));
  }
}
