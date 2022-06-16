import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/pair.dart';
import 'package:Minutes/widgets/secondary_icon_button.dart';
import 'package:flutter/cupertino.dart';
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
          List<Pair<String, Pair<String, Duration>>> minutes =
              viewModel.transcriptTextList.getMinutes();
          return ListView.builder(
            itemCount: minutes.length,
            itemBuilder: (_, index) => RawTextEditor(
              minutes: minutes[index].first,
              data: minutes[index].second,
            ),
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
