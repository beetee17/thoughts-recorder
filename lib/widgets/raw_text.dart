import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:leopard_demo/redux_/audio.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/utils/extensions.dart';

import '../utils/utils.dart';

class RawText extends StatefulWidget {
  final TextEditingController textEditingController;
  const RawText({Key? key, required this.textEditingController})
      : super(key: key);

  @override
  State<RawText> createState() => _RawTextState();
}

class _RawTextState extends State<RawText> {
  @override
  void dispose() {
    TextFormatter.splitText(widget.textEditingController.text,
        store.state.untitled.transcriptTextList);
    widget.textEditingController.dispose();
    super.dispose();
  }

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
          return TextField(
            style: TextStyle(fontSize: 20, color: Colors.white),
            maxLines: null,
            expands: true,
            controller: widget.textEditingController,
          );
        });
  }
}

class RawTextVM {
  List<Pair<String, double>> transcriptTextList;
  String text;
  void Function(int) highlightSpan;
  int? highlightedSpanIndex;
  int audioDuration;
  RawTextVM(this.transcriptTextList, this.text, this.highlightSpan,
      this.highlightedSpanIndex, this.audioDuration);
}
