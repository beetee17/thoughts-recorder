import 'dart:io';

import 'package:Minutes/redux_/files.dart';
import 'package:Minutes/screens/settings_screen.dart';
import 'package:Minutes/screens/transcript_screen.dart';
import 'package:Minutes/utils/spinner.dart';
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

    Settings.getAccessKey().then((_) {
      showSpinnerAfter(context, () => InitLeopardAction().call(store));
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        builder: (context) => const SettingsScreen()));
              },
            ),
          ],
        ),
        body: FilesList(),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          backgroundColor: Colors.blue.shade800,
          onPressed: () {
            ClearAllAction().call(store).then((value) => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => TranscriptScreen()))
                .then((_) => store.dispatch(refreshFiles)));
            // Refresh page when coming back here
          },
        ),
      ),
    );
  }
}
