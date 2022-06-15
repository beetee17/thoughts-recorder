import 'dart:io';

import 'package:Minutes/redux_/files.dart';
import 'package:Minutes/screens/settings_screen.dart';
import 'package:Minutes/screens/transcript_screen.dart';
import 'package:Minutes/utils/colors.dart';
import 'package:Minutes/utils/spinner.dart';
import 'package:Minutes/widgets/files_list.dart';
import 'package:flutter/cupertino.dart';
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
      showSpinnerUntil(
          context,
          () => InitLeopardAction()
              .call(store)
              .then((_) => store.dispatch(refreshFiles)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
        store: store,
        child: Material(
          color: bgColor,
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.info_outline_rounded,
                              color: textColor,
                            ),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                          appBar:
                                              AppBar(title: Text("Tutorial")),
                                          body: Tutorial())));
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.settings,
                              color: textColor,
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Minutes",
                          style: TextStyle(
                              color: textColor,
                              fontSize: 34,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      SizedBox(height: 10),
                      CupertinoSearchTextField(),
                      SizedBox(height: 10),
                      Expanded(
                        child: FilesList(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton(
                      child: Icon(Icons.add),
                      backgroundColor: Colors.blue.shade800,
                      onPressed: () {
                        ClearAllAction().call(store).then((value) =>
                            Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            TranscriptScreen()))
                                .then((_) => store.dispatch(refreshFiles)));
                        // Refresh page when coming back here
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        // child: Material(
        //   child: CupertinoPageScaffold(
        //     backgroundColor: bgColor,
        //     child: CustomScrollView(
        //       slivers: [
        //         CupertinoSliverNavigationBar(
        //           backgroundColor: bgColor,
        // leading: IconButton(
        //   icon: Icon(
        //     Icons.info_outline_rounded,
        //     color: textColor,
        //   ),
        //   onPressed: () {
        //     Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //             builder: (context) => Scaffold(
        //                 appBar: AppBar(title: Text("Tutorial")),
        //                 body: Tutorial())));
        //   },
        // ),
        // trailing: IconButton(
        //   icon: Icon(
        //     Icons.settings,
        //     color: textColor,
        //   ),
        //   onPressed: () {
        //     Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //             builder: (context) => const SettingsScreen()));
        //   },
        // ),
        //           automaticallyImplyLeading: false,
        //           largeTitle: Column(
        //             children: <Widget>[
        //               Container(
        //                 alignment: Alignment.centerLeft,
        // child: Text(
        //   "Minutes",
        //   style: TextStyle(color: textColor),
        //   textAlign: TextAlign.left,
        // ),
        //               ),
        //             ],
        //           ),
        //         ),
        //         SliverFillRemaining(child: FilesList())
        //       ],
        //     ),
        // floatingActionButton: FloatingActionButton(
        //   child: Icon(Icons.add),
        //   backgroundColor: Colors.blue.shade800,
        //   onPressed: () {
        //     ClearAllAction().call(store).then((value) => Navigator.push(context,
        //             MaterialPageRoute(builder: (context) => TranscriptScreen()))
        //         .then((_) => store.dispatch(refreshFiles)));
        //     // Refresh page when coming back here
        //   },
        // ),
        //   ),
        // ),
        );
  }
}
