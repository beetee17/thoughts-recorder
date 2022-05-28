import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:leopard_demo/providers/audio_file_provider.dart';
import 'package:leopard_demo/providers/main_provider.dart';
import 'package:leopard_demo/utils/extensions.dart';
import 'package:leopard_demo/widgets/save_transcript_button.dart';
import 'package:provider/provider.dart';

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
  void initState() {
    super.initState();
  }

  String formatText(rawText) {
    String formattedText = rawText.toUpperCase();
    formattedText = formattedText.replaceAll(' COMMA', ',');
    formattedText = formattedText.replaceAll(' FULL-STOP', '.');
    formattedText = formattedText.replaceAll(' FULL STOP', '.');
    formattedText = formattedText.replaceAll(' PERIOD', '.');
    formattedText = formattedText.replaceAll(' SLASH ', '/');
    formattedText = formattedText.replaceAll('AMPERSAND', '&');
    formattedText = formattedText.replaceAll('START BRACKET', '(');
    formattedText = formattedText.replaceAll(' FINISH BRACKET', ')');
    formattedText = formattedText.replaceAll('START QUOTE', '"');
    formattedText = formattedText.replaceAll(' FINISH QUOTE', '"');
    formattedText = formattedText.replaceAll('NEW LINE ', '\n');
    formattedText = formattedText.replaceAll('MAKE POINT', '\n-');
    formattedText = formattedText.replaceAll('MAKE SECTION', '\n\n##');

    // Deletes sentence preceding DELETE SENTENCE
    formattedText =
        formattedText.replaceAll(RegExp('[^.]+. DELETE SENTENCE'), '');

    // Deletes line preceding DELETE LINE
    formattedText = formattedText.replaceAll(RegExp('[^\n]+. DELETE LINE'), '');

    // Deletes word preceding BACKSPACE
    formattedText =
        formattedText.replaceAll(RegExp(r'\w+(?= +BACKSPACE\b)'), '');

    // Remove any extra whitespace
    formattedText = formattedText.replaceAll(RegExp(' {2,}'), ' ');
    return formattedText.capitalizeSentences().capitalizeNewLines();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void find(int wordIndex, BuildContext context) {
    final provider = context.read<MainProvider>();
    final audio = context.read<AudioProvider>();
    provider.binarySearch(wordIndex).then((frameIndex) {
      if (frameIndex > 0) {
        final double duration = 0.03 / 1024 * frameIndex;
        print(duration);
        audio.seek(min(audio.duration.toDouble() - 200, duration * 1000));
      }
    });
  }

  List<TextSpan> getSpans(String text, BuildContext context) {
    List<String> words = text.split(' ');
    List<TextSpan> spans = [];

    for (int i = 0; i < words.length; i++) {
      spans.add(TextSpan(
          text: '${words[i]} ',
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              print("Word ${words[i]} tapped");
              find(i, context);
            },
          style: TextStyle(color: Colors.white, fontSize: 20)));
    }
    return spans;
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
              formatText(widget.textEditingController.text),
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
                  ? Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: RichText(
                          text: TextSpan(
                              children: getSpans(
                                  widget.textEditingController.text, context))),
                    )
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
