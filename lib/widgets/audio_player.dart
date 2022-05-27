import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AudioPlayerWidget extends StatefulWidget {
  final File audioFile;

  const AudioPlayerWidget({Key? key, required this.audioFile})
      : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  int audioDuration = 100;
  int currentPos = 0;
  String currentPosLabel = "00:00";
  bool isPlaying = false;
  bool finishedPlaying = false;

  AudioPlayer player = AudioPlayer();

  durationToString(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    int hours = d.inHours;
    int minutes = d.inMinutes.remainder(60);
    int seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
    return "$minutes:${twoDigits(seconds)}";
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      player.onDurationChanged.listen((Duration d) {
        setState(() {
          //get the duration of audio
          audioDuration = d.inMilliseconds;
        });
      });

      player.onAudioPositionChanged.listen((Duration p) {
        setState(() {
          //refresh the UI
          currentPos =
              p.inMilliseconds; //get the current position of playing audio

          currentPosLabel = durationToString(p);
        });
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      children: [
        Container(
          child: Text(
            currentPosLabel,
            style: TextStyle(fontSize: 25),
          ),
        ),
        Container(
            child: Slider(
          value: double.parse(currentPos.toString()),
          min: 0,
          max: double.parse(audioDuration.toString()),
          divisions: audioDuration,
          label: currentPosLabel,
          onChanged: (double value) async {
            int seekval = value.round();
            int result = await player.seek(Duration(milliseconds: seekval));
            if (result == 1) {
              //seek successful
              currentPos = seekval;
            } else {
              print("Seek unsuccessful.");
            }
          },
        )),
        Container(
          child: Wrap(
            spacing: 10,
            children: [
              ElevatedButton.icon(
                  onPressed: () async {
                    if (!isPlaying && !finishedPlaying) {
                      int result = await player.play(widget.audioFile.path,
                          isLocal: true);
                      if (result == 1) {
                        //play success
                        setState(() {
                          isPlaying = true;
                          finishedPlaying = true;
                        });
                      } else {
                        print("Error while playing audio.");
                      }
                    } else if (finishedPlaying && !isPlaying) {
                      int result = await player.resume();
                      if (result == 1) {
                        //resume success
                        setState(() {
                          isPlaying = true;
                          finishedPlaying = true;
                        });
                      } else {
                        print("Error on resume audio.");
                      }
                    } else {
                      int result = await player.pause();
                      if (result == 1) {
                        //pause success
                        setState(() {
                          isPlaying = false;
                        });
                      } else {
                        print("Error on pause audio.");
                      }
                    }
                  },
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(isPlaying ? "Pause" : "Play")),
              ElevatedButton.icon(
                  onPressed: () async {
                    int result = await player.stop();
                    if (result == 1) {
                      //stop success
                      setState(() {
                        isPlaying = false;
                        finishedPlaying = false;
                        currentPos = 0;
                      });
                    } else {
                      print("Error on stop audio.");
                    }
                  },
                  icon: Icon(Icons.stop),
                  label: Text("Stop")),
            ],
          ),
        )
      ],
    ));
  }
}
