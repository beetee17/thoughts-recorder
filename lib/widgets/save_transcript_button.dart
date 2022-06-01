import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/widgets/secondary_icon_button.dart';
import 'package:share_extend/share_extend.dart';

class SaveTranscriptButton extends StatelessWidget {
  const SaveTranscriptButton({Key? key}) : super(key: key);

  void shareTranscript(text) async {
    ShareExtend.share(text, "text");
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, SaveTranscriptButtonVM>(
        converter: (store) =>
            SaveTranscriptButtonVM(store.state.untitled.transcriptText),
        builder: (_, viewModel) {
          return SecondaryIconButton(
              onPress: () => shareTranscript(viewModel.text),
              margin: EdgeInsets.only(top: 10.0, right: 10.0),
              icon:
                  Transform.scale(scaleX: -1, child: Icon(Icons.reply_sharp)));
        });
  }
}

class SaveTranscriptButtonVM {
  String text;
  SaveTranscriptButtonVM(this.text);
}
