import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
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
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton(
              onPressed: () => shareTranscript(viewModel.text),
              child: const Text('Share Text'),
            ),
          );
        });
  }
}

class SaveTranscriptButtonVM {
  String text;
  SaveTranscriptButtonVM(this.text);
}
