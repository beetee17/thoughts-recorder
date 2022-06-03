import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:leopard_demo/widgets/audio_player_context_menu.dart';

import '../redux_/audio.dart';
import 'widget_with_shadow.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({Key? key}) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  @override
  void initState() {
    super.initState();

    print("INIT PLAYER");
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
                Transform.translate(
                  offset: Offset(0, 10),
                  child: Container(
                      child: Slider(
                    value: double.parse(viewModel.audio.currentPos.toString()),
                    min: 0,
                    max: double.parse(viewModel.audio.duration.toString()),
                    divisions: viewModel.audio.duration,
                    label: viewModel.audio.currentPosLabel,
                    onChanged: AudioState.seek,
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        viewModel.audio.currentPosLabel,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                          Duration(milliseconds: viewModel.audio.duration)
                              .toAudioDurationString(),
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Spacer(),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.blue.shade800,
                            borderRadius: BorderRadius.all(Radius.circular(
                                    25.0) //                 <--- border radius here
                                )),
                        padding: EdgeInsets.only(
                            left: viewModel.audio.isPlaying ? 0 : 4.0),
                        child: WithShadow(
                            child: IconButton(
                          onPressed: () =>
                              viewModel.audio.togglePlayPause(viewModel.file!),
                          icon: Icon(viewModel.audio.isPlaying
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill),
                          iconSize: 45,
                          color: Colors.white,
                        )),
                      ),
                      Expanded(child: AudioPlayerContextMenu())
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }
}

class AudioPlayerWidgetVM {
  AudioState audio;
  File? file;
  AudioPlayerWidgetVM(this.audio, this.file);
  @override
  bool operator ==(other) {
    return (other is AudioPlayerWidgetVM) &&
        (audio == other.audio) &&
        (file == other.file);
  }

  @override
  int get hashCode {
    return Object.hash(audio, file);
  }
}
