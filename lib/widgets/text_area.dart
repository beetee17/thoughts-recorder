import 'package:flutter/material.dart';
import 'package:leopard_demo/widgets/raw_text.dart';
import 'package:leopard_demo/widgets/save_transcript_button.dart';

import 'formatted_text.dart';

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
