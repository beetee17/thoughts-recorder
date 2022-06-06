import 'dart:io';

import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/transcriptClasses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux_/rootStore.dart';

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

    // Find files
    _transcripts = Future.wait(
        widget.files.map((e) => TranscriptFileHandler.load(e.path)).toList());
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
                return StoreProvider(
                  store: store,
                  child: ListView(
                      children: snapshot.data!
                          .map(
                            (transcript) => Card(
                              elevation: 5,
                              margin: const EdgeInsets.all(10.0),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: SizedBox(
                                    height: 100,
                                    child: Center(
                                        child: Text(
                                            transcript.audio.getFileName()))),
                              ),
                            ),
                          )
                          .toList()),
                );
              }
          }
        });
  }
}
