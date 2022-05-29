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
    // context.read<AudioProvider>().initialisePlayer();
    AudioState.initialisePlayer();
  }

  @override
  void dispose() {
    super.dispose();
    context.read<AudioProvider>().player.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MainProvider provider = context.watch<MainProvider>();
    print(provider.file);

    return StoreConnector<AppState, AudioState>(
        converter: (store) => store.state.audio,
        builder: (_, audio) {
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
                onChanged: AudioState.seek,
              )),
              Container(
                child: Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton.icon(
                        onPressed: () => audio.togglePlayPause(provider.file!),
                        icon: Icon(
                            audio.isPlaying ? Icons.pause : Icons.play_arrow),
                        label: Text(audio.isPlaying ? "Pause" : "Play")),
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
