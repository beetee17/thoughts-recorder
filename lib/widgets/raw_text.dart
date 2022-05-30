import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/audio.dart';
import 'package:leopard_demo/redux_/rootStore.dart';

import '../utils/utils.dart';

class RawText extends StatefulWidget {
  const RawText({Key? key}) : super(key: key);

  @override
  State<RawText> createState() => _RawTextState();
}

class _RawTextState extends State<RawText> {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RawTextVM>(
        converter: (store) => RawTextVM(
            store.state.untitled.transcriptTextList,
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

          return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: RichText(text: TextSpan(children: spans)));
        });
  }
}

class RawTextVM {
  List<Pair<String, double>> transcriptTextList;
  void Function(int) highlightSpan;
  int? highlightedSpanIndex;
  int audioDuration;
  RawTextVM(this.transcriptTextList, this.highlightSpan,
      this.highlightedSpanIndex, this.audioDuration);
}
