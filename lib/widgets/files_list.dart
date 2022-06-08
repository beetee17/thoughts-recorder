import 'package:Minutes/redux_/files.dart';
import 'package:Minutes/utils/transcriptClasses.dart';
import 'package:Minutes/widgets/secondary_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux_/rootStore.dart';
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
        converter: (store) => FilesListVM(store.state.files.transcripts),
        builder: (_, viewModel) {
          return RefreshIndicator(
            onRefresh: () => store.dispatch(refreshFiles),
            child: ListView(
                children: viewModel.transcripts.isEmpty
                    ? [
                        Text(
                            'No Transcriptions Found. Click the + Button to start transcribing!')
                      ]
                    : viewModel.transcripts
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
                                        transcript.filename,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          SecondaryIconButton(
                                              onPress: () {
                                                store.dispatch(
                                                    loadTranscript(transcript));

                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            TranscriptScreen(
                                                              transcript:
                                                                  transcript,
                                                            ))).then((_) =>
                                                    store.dispatch(
                                                        refreshFiles));
                                              },
                                              icon: Icon(CupertinoIcons
                                                  .arrow_right_circle_fill),
                                              margin: EdgeInsets.zero),
                                          SecondaryIconButton(
                                              onPress: () {
                                                TranscriptFileHandler.delete(
                                                    context, transcript);
                                              },
                                              icon: Icon(
                                                CupertinoIcons
                                                    .trash_circle_fill,
                                                color: Colors.redAccent,
                                              ),
                                              margin: EdgeInsets.zero),
                                        ],
                                      )
                                    ],
                                  )),
                            ),
                          ),
                        )
                        .toList()),
          );
        });
  }
}

class FilesListVM {
  List<Transcript> transcripts;
  FilesListVM(this.transcripts);
  @override
  bool operator ==(other) {
    return (other is FilesListVM) && (transcripts == other.transcripts);
  }

  @override
  int get hashCode {
    return transcripts.hashCode;
  }
}
