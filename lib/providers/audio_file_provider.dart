import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:leopard_demo/utils/extensions.dart';

class AudioFileProvider with ChangeNotifier {
  int _duration = 100;
  int get duration => _duration;

  int _currentPos = 0;
  int get currentPos => _currentPos;

  String _currentPosLabel = "00:00";
  String get currentPosLabel => _currentPosLabel;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _finishedPlaying = false;
  bool get finishedPlaying => _finishedPlaying;

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  File? _userSelectedFile;
  File? get userSelectedFile => _userSelectedFile;

  // File Picker Functions
  void pickFile() {
    // From SDK Documentation:
    // The file needs to have a sample rate equal to or greater than Leopard.sampleRate.
    //The supported formats are: FLAC, MP3, Ogg, Opus, Vorbis, WAV, and WebM.
    FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: [
      'flac',
      'mp3',
      'ogg',
      'opus',
      'wav',
      'webm'
    ]).then((res) {
      if (res != null) {
        _userSelectedFile = File(res.files.single.path!);
        notifyListeners();
      } else {
        // User canceled the picker
      }
    });
  }

  void removeSelectedFile() {
    _userSelectedFile = null;
    notifyListeners();
  }

  // Initialise Player
  void initialisePlayer() {
    Future.delayed(Duration.zero, () async {
      player.onDurationChanged.listen((Duration d) {
        //get the duration of audio
        _duration = d.inMilliseconds;
        notifyListeners();
      });

      player.onAudioPositionChanged.listen((Duration p) {
        //refresh the UI
        _currentPos =
            p.inMilliseconds; //get the current position of playing audio

        _currentPosLabel = p.toAudioDurationString();
        notifyListeners();
      });
    });
    notifyListeners();
  }

  // Audio Player Functions
  seek(double value) async {
    int seekval = value.round();
    int result = await player.seek(Duration(milliseconds: seekval));
    if (result == 1) {
      //seek successful
      _currentPos = seekval;
    } else {
      print("Seek unsuccessful.");
    }
    notifyListeners();
  }

  togglePlayPause() async {
    if (!isPlaying && !finishedPlaying) {
      int result = await player.play(_userSelectedFile!.path, isLocal: true);
      if (result == 1) {
        //play success
        _isPlaying = true;
        _finishedPlaying = true;
      } else {
        print("Error while playing audio.");
      }
    } else if (finishedPlaying && !isPlaying) {
      int result = await player.resume();
      if (result == 1) {
        //resume success
        _isPlaying = true;
        _finishedPlaying = true;
      } else {
        print("Error on resume audio.");
      }
    } else {
      int result = await player.pause();
      if (result == 1) {
        //pause success
        _isPlaying = false;
      } else {
        print("Error on pause audio.");
      }
    }
    notifyListeners();
  }

  stopPlayer() async {
    int result = await player.stop();
    if (result == 1) {
      //stop success
      _isPlaying = false;
      _finishedPlaying = false;
      _currentPos = 0;
    } else {
      print("Error on stop audio.");
    }
    notifyListeners();
  }
}
