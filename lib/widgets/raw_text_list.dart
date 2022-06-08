import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/widgets/raw_text_editor.dart';

import '../utils/transcript_pair.dart';

class RawTextList extends StatefulWidget {
  const RawTextList({Key? key}) : super(key: key);

  @override
  State<RawTextList> createState() => _RawTextListState();
}

class _RawTextListState extends State<RawTextList> {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RawTextListVM>(
        distinct: true,
        converter: ((store) =>
            RawTextListVM(store.state.transcript.transcriptTextList)),
        builder: (_, viewModel) {
          return ListView(
            children: viewModel.transcriptTextList
                .asMap()
                .map((index, partialTranscript) {
                  return MapEntry(
                      index,
                      RawTextEditor(
                        index: index,
                        partialTranscript: partialTranscript,
                      ));
                })
                .values
                .toList(),
          );
        });
  }
}

class RawTextListVM {
  List<TranscriptPair> transcriptTextList;
  RawTextListVM(this.transcriptTextList);
  @override
  bool operator ==(other) {
    return (other is RawTextListVM) &&
        (transcriptTextList == other.transcriptTextList);
  }

  @override
  int get hashCode {
    return transcriptTextList.hashCode;
  }
}
