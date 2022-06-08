import 'package:Minutes/redux_/files.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/spinner.dart';
import 'package:Minutes/utils/transcriptClasses.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux_/rootStore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../redux_/transcript.dart';
import '../screens/transcript_screen.dart';

class FilesList extends StatefulWidget {
  const FilesList({Key? key}) : super(key: key);

  @override
  State<FilesList> createState() => _FilesListState();
}

class _FilesListState extends State<FilesList> {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, FilesListVM>(
        distinct: true,
        converter: (store) => FilesListVM(store.state.files.all),
        builder: (ctx, viewModel) {
          return RefreshIndicator(
              onRefresh: () => store.dispatch(refreshFiles),
              child: ListView(
                  children: viewModel.files
                      .map((transcript) => Slidable(
                            // The end action pane is the one at the right or the bottom side.
                            endActionPane: ActionPane(
                              motion: ScrollMotion(),
                              children: [
                                SlidableAction(
                                  // An action can be bigger than the others.
                                  onPressed: (_) {},
                                  backgroundColor: CupertinoColors.activeBlue,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: 'Rename',
                                ),
                                SlidableAction(
                                  onPressed: (_) {
                                    showSpinnerUntil(
                                        ctx,
                                        () => TranscriptFileHandler.delete(
                                            ctx, transcript));
                                  },
                                  backgroundColor:
                                      CupertinoColors.destructiveRed,
                                  foregroundColor: Colors.white,
                                  icon: CupertinoIcons.trash,
                                  label: 'Delete',
                                )
                              ],
                            ),

                            // The child of the Slidable is what the user sees when the
                            // component is not dragged.
                            child: GestureDetector(
                              onTap: () {
                                store.dispatch(loadTranscript(transcript));

                                Navigator.push(
                                    ctx,
                                    MaterialPageRoute(
                                        builder: (context) => TranscriptScreen(
                                              transcript: transcript,
                                            ))).then(
                                    (_) => store.dispatch(refreshFiles));
                              },
                              child: Center(
                                child: Card(
                                    elevation: 5,
                                    margin: const EdgeInsets.all(5.0),
                                    child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: SizedBox(
                                            height: 100,
                                            width: double.infinity,
                                            child: Center(
                                              child: Text(
                                                transcript
                                                    .audio.nameWithoutExtension,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            )))),
                              ),
                            ),
                          ))
                      .toList()));
        });
  }
}

class FilesListVM {
  List<SaveFileContents> files;
  FilesListVM(this.files);
  @override
  bool operator ==(other) {
    return (other is FilesListVM) && (files == other.files);
  }

  @override
  int get hashCode {
    return files.hashCode;
  }
}
