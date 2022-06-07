import 'dart:io';

import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/transcriptClasses.dart';
import 'package:Minutes/widgets/just_audio_player.dart';
import 'package:Minutes/widgets/secondary_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux_/leopard.dart';
import '../redux_/rootStore.dart';
import '../redux_/transcript.dart';
import '../screens/transcript_screen.dart';
import '../utils/persistence.dart';

class FilesList extends StatefulWidget {
  final List<File> files;
  const FilesList({Key? key, required this.files}) : super(key: key);

  @override
  State<FilesList> createState() => _FilesListState();
}

class _FilesListState extends State<FilesList> {
  late Future<List<Transcript>> _transcripts;
  @override
  void initState() {
    super.initState();

    // Decode files to transcripts
    _transcripts = Future.wait(
        widget.files.map((e) => TranscriptFileHandler.load(e.path)).toList());

    Settings.getAccessKey().then((value) {
      showDialog(
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
        context: context,
      );
      InitLeopardAction()
          .call(store)
          .then((value) => Navigator.of(context).pop());
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Transcript>>(
        future: _transcripts,
        builder:
            (BuildContext context, AsyncSnapshot<List<Transcript>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const CircularProgressIndicator();

            default:
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return ListView(
                    children: snapshot.data!
                        .map(
                          (transcript) => Card(
                            elevation: 5,
                            margin: const EdgeInsets.all(10.0),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: SizedBox(
                                  height: 100,
                                  child: Column(
                                    children: [
                                      Text(
                                        transcript.audio.getFileName(),
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      SecondaryIconButton(
                                          onPress: () {
                                            store.dispatch(
                                                loadTranscript(transcript));
                                            JustAudioPlayerWidgetState.init(
                                                transcript.audio);
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        TranscriptScreen()));
                                          },
                                          icon: Icon(CupertinoIcons
                                              .arrow_right_circle_fill),
                                          margin: EdgeInsets.zero)
                                    ],
                                  )),
                            ),
                          ),
                        )
                        .toList());
              }
          }
        });
  }
}
