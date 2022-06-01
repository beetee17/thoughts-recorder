import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:leopard_demo/widgets/raw_text.dart';
import 'package:leopard_demo/widgets/save_transcript_button.dart';

import '../redux_/audio.dart';
import '../redux_/rootStore.dart';
import '../utils/utils.dart';

class TextArea extends StatefulWidget {
  final TextEditingController textEditingController;
  const TextArea({Key? key, required this.textEditingController})
      : super(key: key);

  @override
  State<TextArea> createState() => _TextAreaState();
}

class _TextAreaState extends State<TextArea> {
  bool showRawText = false;

  @override
  void dispose() {
    super.dispose();
    widget.textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Widget formattedTextView = SingleChildScrollView(
    //     scrollDirection: Axis.vertical,
    //     padding: EdgeInsets.all(10),
    //     physics: RangeMaintainingScrollPhysics(),
    //     child: Align(
    //         alignment: Alignment.topLeft,
    //         child: Text(
    //           widget.textEditingController.text.formatText(),
    //           textAlign: TextAlign.left,
    //           style: TextStyle(color: Colors.white, fontSize: 20),
    //         )));

    return Expanded(
      flex: 5,
      child: Column(children: [
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showRawText = !showRawText;
                    });
                  },
                  child: Text(
                      '${showRawText ? 'View Formatted' : 'Edit Raw'} Text'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: SaveTranscriptButton(),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
              alignment: Alignment.topCenter,
              color: Color(0xff25187e),
              margin: EdgeInsets.all(10),
              child: showRawText
                  ? RawText(
                      textEditingController: widget.textEditingController,
                    )
                  : FormattedTextView(text: widget.textEditingController.text)),
        ),
      ]),
    );
  }
}

class FormattedTextView extends StatefulWidget {
  final String text;
  const FormattedTextView({Key? key, required this.text}) : super(key: key);

  @override
  State<FormattedTextView> createState() => _FormattedTextViewState();
}

class _FormattedTextViewState extends State<FormattedTextView> {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RawTextVM>(
        converter: (store) => RawTextVM(
            store.state.untitled.transcriptTextList,
            store.state.untitled.transcriptText,
            store.state.untitled.highlightSpan,
            store.state.untitled.highlightedSpanIndex,
            store.state.audio.duration),
        builder: (_, viewModel) {
          List<TextSpan> spans = viewModel.transcriptTextList
              .asMap()
              .map((index, pair) {
                void onTapSpan() {
                  print("Text: ${pair.first} tapped");
                  viewModel.highlightSpan(index);
                  final seekTimeInMS = min(
                      viewModel.audioDuration.toDouble(), pair.second * 1000);
                  print('seeking: ${seekTimeInMS / 1000}s');
                  AudioState.seek(seekTimeInMS);
                }

                Paint? shouldHighlightSpan() {
                  if (viewModel.highlightedSpanIndex == index) {
                    return Paint()..color = Colors.greenAccent;
                  }
                  return null;
                }

                TextSpan span = TextSpan(
                    text: '${pair.first} ',
                    recognizer: TapGestureRecognizer()..onTap = onTapSpan,
                    style: TextStyle(
                        color: Colors.white,
                        background: shouldHighlightSpan(),
                        fontSize: 20));
                return MapEntry(index, span);
              })
              .values
              .toList();

          return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              padding: EdgeInsets.all(10),
              physics: RangeMaintainingScrollPhysics(),
              child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: RichText(text: TextSpan(children: spans))));
        });
  }
}

class FormattedTextVM {
  List<Pair<String, double>> transcriptTextList;
  String text;
  void Function(int) highlightSpan;
  int? highlightedSpanIndex;
  int audioDuration;
  FormattedTextVM(this.transcriptTextList, this.text, this.highlightSpan,
      this.highlightedSpanIndex, this.audioDuration);
}
