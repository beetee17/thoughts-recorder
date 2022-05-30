import 'package:flutter/material.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:leopard_demo/widgets/raw_text.dart';
import 'package:leopard_demo/widgets/save_transcript_button.dart';

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
    Widget formattedTextView = SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.all(10),
        physics: RangeMaintainingScrollPhysics(),
        child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              widget.textEditingController.text.formatText(),
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.white, fontSize: 20),
            )));

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
                  ? RawText()
                  // ? Padding(
                  //     padding: const EdgeInsets.only(left: 10.0),
                  //     child: TextField(
                  //       style: TextStyle(color: Colors.white, fontSize: 20),
                  //       controller: widget.textEditingController,
                  //       textInputAction: TextInputAction.newline,
                  //       keyboardType: TextInputType.multiline,
                  //       minLines: null,
                  //       maxLines:
                  //           null, // If this is null, there is no limit to the number of lines, and the text container will start with enough vertical space for one line and automatically grow to accommodate additional lines as they are entered.
                  //       expands:
                  //           true, // If set to true and wrapped in a parent widget like [Expanded] or [SizedBox], the input will expand to fill the parent.
                  //     ),
                  //   )
                  : formattedTextView),
        ),
      ]),
    );
  }
}
