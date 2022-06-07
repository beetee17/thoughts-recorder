import 'dart:io';

import 'package:Minutes/screens/settings_screen.dart';
import 'package:Minutes/screens/transcript_screen.dart';
import 'package:Minutes/utils/transcriptClasses.dart';
import 'package:Minutes/widgets/files_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux_/leopard.dart';
import '../redux_/rootStore.dart';
import '../utils/persistence.dart';
import '../widgets/tutorial.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({Key? key}) : super(key: key);

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  late Future<List<File>> _files;
  @override
  void initState() {
    super.initState();

    // Find txt files
    _files = TranscriptFileHandler.appFilesDirectory.then((dir) => dir
        .list()
        .toList()
        .then((entities) => Future.delayed(
            Duration.zero,
            () => entities
                .whereType<File>()
                .where((file) => file.path.endsWith('.txt'))
                .toList())));
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
    return FutureBuilder<List<File>>(
        future: _files,
        builder: (BuildContext context, AsyncSnapshot<List<File>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const CircularProgressIndicator();

            default:
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return StoreProvider(
                  store: store,
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('Minutes'),
                      leading: IconButton(
                        icon: Icon(
                          Icons.info_outline_rounded,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                      appBar: AppBar(title: Text("Tutorial")),
                                      body: Tutorial())));
                        },
                      ),
                      actions: <Widget>[
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen()));
                          },
                        ),
                      ],
                    ),
                    body: FilesList(files: snapshot.data!),
                    floatingActionButton: FloatingActionButton(
                      child: Icon(Icons.add),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TranscriptScreen()));
                      },
                    ),
                  ),
                );
              }
          }
        });
  }
}
