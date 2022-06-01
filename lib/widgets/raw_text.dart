import 'package:flutter/material.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/utils/extensions.dart';

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
    return TextField(
        style: TextStyle(fontSize: 20, color: Colors.white),
        maxLines: null,
        expands: true,
        controller: widget.textEditingController);
  }
}
