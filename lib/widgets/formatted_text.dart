import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/utils/extensions.dart';

import '../redux_/audio.dart';
import '../redux_/rootStore.dart';
import '../utils/pair.dart';

class FormattedTextView extends StatefulWidget {
  final String text;
  const FormattedTextView({Key? key, required this.text}) : super(key: key);

  @override
  State<FormattedTextView> createState() => _FormattedTextViewState();
}

class _FormattedTextViewState extends State<FormattedTextView> {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, FormattedTextVM>(
        converter: (store) => FormattedTextVM(
            store.state.untitled.transcriptTextList,
            store.state.untitled.transcriptText,
            store.state.untitled.highlightSpan,
            store.state.untitled.highlightedSpanIndex,
            store.state.audio.duration),
        builder: (_, viewModel) {
          List<TextSpan> spans =
              TextFormatter.splitText(widget.text, viewModel.transcriptTextList)
                  .asMap()
                  .map((index, pair) {
                    void onTapSpan() {
                      print("Text: ${pair.first} tapped");
                      final seekTimeInMS = min(
                          viewModel.audioDuration.toDouble(),
                          pair.second * 1000);
                      print('seeking: ${seekTimeInMS / 1000}s');
                      AudioState.seek(seekTimeInMS);
                    }

                    TextStyle shouldHighlightSpan() {
                      if (viewModel.highlightedSpanIndex == index) {
                        return TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold);
                      }
                      return TextStyle(color: Colors.black54);
                    }

                    TextSpan span = TextSpan(
                        text: '${pair.first} ',
                        recognizer: TapGestureRecognizer()..onTap = onTapSpan,
                        style: TextStyle(fontSize: 20)
                            .merge(shouldHighlightSpan()));
                    return MapEntry(index, span);
                  })
                  .values
                  .toList();

          return Container(
            margin: EdgeInsets.only(top: 10, bottom: 15),
            child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: RangeMaintainingScrollPhysics(),
                child: RichText(text: TextSpan(children: spans))),
          );
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
  @override
  bool operator ==(other) {
    return (other is FormattedTextVM) &&
        (transcriptTextList == other.transcriptTextList) &&
        (text == other.text) &&
        (highlightSpan == other.highlightSpan) &&
        (audioDuration == other.audioDuration);
  }

  @override
  int get hashCode {
    return Object.hash(transcriptTextList, text, highlightSpan,
        highlightedSpanIndex, audioDuration);
  }
}
