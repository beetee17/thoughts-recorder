import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:leopard_demo/widgets/secondary_icon_button.dart';
import 'package:share_extend/share_extend.dart';

import '../utils/pair.dart';

class SaveTranscriptButton extends StatelessWidget {
  const SaveTranscriptButton({Key? key}) : super(key: key);

  void shareTranscript(String text) async {
    ShareExtend.share(text, "text");
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, SaveTranscriptButtonVM>(
        converter: (store) =>
            SaveTranscriptButtonVM(store.state.untitled.transcriptTextList),
        builder: (_, viewModel) {
          return SecondaryIconButton(
              onPress: () => shareTranscript(
                  TextFormatter.formatTextList(viewModel.transcriptTextList)
                      .map((pair) => pair.first)
                      .join(' ')),
              margin: EdgeInsets.only(top: 10.0, right: 10.0),
              icon:
                  Transform.scale(scaleX: -1, child: Icon(Icons.reply_sharp)));
        });
  }
}

class SaveTranscriptButtonVM {
  List<Pair<String, Duration>> transcriptTextList;

  SaveTranscriptButtonVM(this.transcriptTextList);
  @override
  bool operator ==(other) {
    return (other is SaveTranscriptButtonVM) &&
        (transcriptTextList == other.transcriptTextList);
  }

  @override
  int get hashCode {
    return transcriptTextList.hashCode;
  }
}
