import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/providers/audio_file_provider.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:provider/provider.dart';

import '../providers/main_provider.dart';
import '../redux_/audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({Key? key}) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  @override
  void initState() {
    super.initState();
    AudioState.initialisePlayer();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AudioPlayerWidgetVM>(
        converter: (store) =>
            AudioPlayerWidgetVM(store.state.audio, store.state.untitled.file),
        builder: (_, viewModel) {
          return Container(
              child: Column(
            children: [
              Container(
                child: Text(
                  viewModel.audio.currentPosLabel,
                  style: TextStyle(fontSize: 25),
                ),
              ),
              Container(
                  child: Slider(
                value: double.parse(viewModel.audio.currentPos.toString()),
                min: 0,
                max: double.parse(viewModel.audio.duration.toString()),
                divisions: viewModel.audio.duration,
                label: viewModel.audio.currentPosLabel,
                onChanged: AudioState.seek,
              )),
              Container(
                child: Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton.icon(
                        onPressed: () =>
                            viewModel.audio.togglePlayPause(viewModel.file!),
                        icon: Icon(viewModel.audio.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow),
                        label:
                            Text(viewModel.audio.isPlaying ? "Pause" : "Play")),
                    ElevatedButton.icon(
                        onPressed: AudioState.stopPlayer,
                        icon: Icon(Icons.stop),
                        label: Text("Stop")),
                  ],
                ),
              )
            ],
          ));
        });
  }
}

class AudioPlayerWidgetVM {
  AudioState audio;
  File? file;
  AudioPlayerWidgetVM(this.audio, this.file);
}
