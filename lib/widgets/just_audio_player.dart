// This is a minimal example demonstrating a play/pause button and a seek bar.
// More advanced examples demonstrating other features can be found in the same
// directory as this example in the GitHub repository.

import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/widgets/audio_player_context_menu.dart';
import 'package:Minutes/widgets/seek_bar.dart';
import 'package:Minutes/widgets/widget_with_shadow.dart';
import 'package:rxdart/rxdart.dart';

import '../redux_/audio.dart';

class JustAudioPlayerWidget extends StatefulWidget {
  final File file;
  const JustAudioPlayerWidget({Key? key, required this.file}) : super(key: key);

  @override
  JustAudioPlayerWidgetState createState() => JustAudioPlayerWidgetState();
}

class JustAudioPlayerWidgetState extends State<JustAudioPlayerWidget>
    with WidgetsBindingObserver {
  static final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    ambiguate(WidgetsBinding.instance)!.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    init(widget.file);
  }

  static Future<void> init(File file) async {
    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;

    await session.configure(const AudioSessionConfiguration.speech());

    // Listen to errors during playback.
    player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });

    player.positionStream.listen((event) {
      store.dispatch(AudioPositionChangeAction(event));
    });

    player.durationStream.listen((event) {
      if (event != null) {
        store.dispatch(AudioDurationChangeAction(event));
      }
    });
    // Try to load audio from source and catch any errors.
    try {
      await player.setFilePath(file.path);
    } catch (e) {
      print("Error loading audio source ${file.path}: $e");
    }
  }

  @override
  void dispose() {
    ambiguate(WidgetsBinding.instance)!.removeObserver(this);
    // Release decoders and buffers back to the operating system making them
    // available for other apps to use.
    // player.dispose();
    player.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
      player.stop();
    }
  }

  /// Collects the data useful for displaying in a seek bar, using a handy
  /// feature of rx_dart to combine the 3 streams of interest into one.
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          player.positionStream,
          player.bufferedPositionStream,
          player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Display play/pause button and volume/speed sliders.
        ControlButtons(player),
        // Display seek bar. Using StreamBuilder, this widget rebuilds
        // each time the position, buffered position or duration changes.
        StreamBuilder<PositionData>(
          stream: _positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data;
            return SeekBar(
              duration: positionData?.duration ?? Duration.zero,
              position: positionData?.position ?? Duration.zero,
              bufferedPosition: positionData?.bufferedPosition ?? Duration.zero,
              onChangeEnd: player.seek,
            );
          },
        ),
      ],
    );
  }
}

/// Displays the play/pause button and volume/speed sliders.
class ControlButtons extends StatelessWidget {
  final AudioPlayer player;

  const ControlButtons(this.player, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Opens volume slider dialog
        // IconButton(
        //   icon: const Icon(Icons.volume_up),
        //   onPressed: () {
        //     showSliderDialog(
        //       context: context,
        //       title: "Adjust volume",
        //       divisions: 10,
        //       min: 0.0,
        //       max: 1.0,
        //       value: player.volume,
        //       stream: player.volumeStream,
        //       onChanged: player.setVolume,
        //     );
        //   },
        // ),

        // Opens speed slider dialog
        StreamBuilder<double>(
          stream: player.speedStream,
          builder: (context, snapshot) => IconButton(
            icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              showSliderDialog(
                context: context,
                title: "Adjust speed",
                divisions: 10,
                min: 0.5,
                max: 1.5,
                value: player.speed,
                stream: player.speedStream,
                onChanged: player.setSpeed,
              );
            },
          ),
        ),

        /// This StreamBuilder rebuilds whenever the player state changes, which
        /// includes the playing/paused state and also the
        /// loading/buffering/ready state. Depending on the state we show the
        /// appropriate button or loading indicator.
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 45.0,
                height: 45.0,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return ControlButton(
                icon: Icon(CupertinoIcons.play_fill),
                onPress: player.play,
                padding: EdgeInsets.only(left: 4),
              );
            } else if (processingState != ProcessingState.completed) {
              return ControlButton(
                icon: Icon(CupertinoIcons.pause_fill),
                onPress: player.pause,
                padding: EdgeInsets.zero,
              );
            } else {
              return ControlButton(
                icon: Icon(Icons.replay),
                onPress: () => player.seek(Duration.zero),
                padding: EdgeInsets.zero,
              );
            }
          },
        ),

        AudioPlayerContextMenu()
      ],
    );
  }
}

class ControlButton extends StatelessWidget {
  final Icon icon;
  final EdgeInsets padding;
  final Function() onPress;
  const ControlButton(
      {Key? key,
      required this.icon,
      required this.onPress,
      required this.padding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.blue.shade800,
          borderRadius: BorderRadius.all(Radius.circular(25.0) //
              )),
      padding: padding,
      child: WithShadow(
          child: IconButton(
        onPressed: onPress,
        icon: icon,
        iconSize: 45,
        color: Colors.white,
      )),
    );
  }
}
