import 'package:Minutes/redux_/files.dart';
import 'package:Minutes/utils/colors.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/spinner.dart';
import 'package:Minutes/utils/text_field_dialog.dart';
import 'package:Minutes/utils/save_file_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux_/rootStore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../redux_/transcript.dart';
import '../screens/transcript_screen.dart';
import '../utils/save_file_contents.dart';

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
                                  onPressed: (_) {
                                    showTextInputDialog(
                                        ctx,
                                        Text("Rename File"),
                                        transcript.audio.nameWithoutExtension,
                                        (newName) async {
                                      await SaveFileHandler.rename(
                                          ctx, transcript, newName);
                                      store.dispatch(refreshFiles);
                                    });
                                  },
                                  backgroundColor: CupertinoColors.activeBlue,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: 'Rename',
                                ),
                                SlidableAction(
                                  onPressed: (_) {
                                    showSpinnerUntil(
                                        ctx,
                                        () => SaveFileHandler.delete(
                                            ctx, transcript)).then((value) =>
                                        store.dispatch(refreshFiles));
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
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(15))),
                                    color: accentColor,
                                    elevation: 5,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 5.0),
                                    child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: SizedBox(
                                            height: 100,
                                            width: double.infinity,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Text(
                                                  transcript.audio
                                                      .nameWithoutExtension,
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                Text(
                                                  transcript.parsedCreationDate,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          unfocusedTextColor),
                                                )
                                              ],
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
