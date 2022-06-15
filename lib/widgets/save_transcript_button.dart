import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Minutes/redux_/rootStore.dart';
import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/widgets/secondary_icon_button.dart';
import 'package:share_extend/share_extend.dart';

import '../utils/transcript_pair.dart';

class SaveTranscriptButton extends StatelessWidget {
  const SaveTranscriptButton({Key? key}) : super(key: key);

  void shareTranscript(String text) async {
    ShareExtend.share(text, "text");
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, SaveTranscriptButtonVM>(
        distinct: true,
        converter: (store) =>
            SaveTranscriptButtonVM(store.state.transcript.transcriptText),
        builder: (_, viewModel) {
          return SecondaryIconButton(
              onPress: () => shareTranscript(viewModel.transcriptText),
              margin: EdgeInsets.only(top: 10.0, right: 10.0),
              icon:
                  Transform.scale(scaleX: -1, child: Icon(Icons.reply_sharp)));
        });
  }
}

class SaveTranscriptButtonVM {
  String transcriptText;

  SaveTranscriptButtonVM(this.transcriptText);
  @override
  bool operator ==(other) {
    return (other is SaveTranscriptButtonVM) &&
        (transcriptText == other.transcriptText);
  }

  @override
  int get hashCode {
    return transcriptText.hashCode;
  }
}
