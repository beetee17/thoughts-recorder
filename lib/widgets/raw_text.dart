import 'package:flutter/material.dart';

class RawText extends StatefulWidget {
  final TextEditingController textEditingController;
  const RawText({Key? key, required this.textEditingController})
      : super(key: key);

  @override
  State<RawText> createState() => _RawTextState();
}

class _RawTextState extends State<RawText> {
  @override
  Widget build(BuildContext context) {
    return TextField(
        style: TextStyle(fontSize: 20),
        expands: true,
        maxLines: null,
        decoration: InputDecoration(border: InputBorder.none),
        controller: widget.textEditingController);
  }
}
