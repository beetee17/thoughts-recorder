import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        style: GoogleFonts.rubik(
            fontSize: 28, fontWeight: FontWeight.w500, height: 1.4),
        expands: true,
        maxLines: null,
        decoration: InputDecoration.collapsed(hintText: null),
        controller: widget.textEditingController);
  }
}
