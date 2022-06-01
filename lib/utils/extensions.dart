import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/redux_/untitled.dart';
import 'package:leopard_demo/utils/utils.dart';

import '../redux_/audio.dart';

extension StringCasingExtension on String {
  String toCapitalized() => length > 0
      ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}'
      : ''; // TODO: Capitalize first index of letter
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
  String capitalizeSentences() =>
      toCapitalized().split('. ').map((str) => str.toCapitalized()).join('. ');
  String capitalizeNewLines() =>
      toCapitalized().split('\n').map((str) => str.toCapitalized()).join('\n');
}

extension TextFormatter on String {
  static List<Pair<String, double>> splitText(
      String editedText, List<Pair<String, double>> transcriptTextList) {
    RegExp regex = RegExp(r'\[(.*?)\]');
    List<Pair<String, double>> res = [];
    int index = 0;
    editedText.splitMapJoin(
      regex,
      onMatch: (Match match) {
        res.add(transcriptTextList[index]
            .map((left) => match.group(1)!, (right) => right));
        index++;
        return '';
      },
    );

    final tmp = res
        .map((pair) =>
            pair.map((first) => first.formatText(), (second) => second))
        .toList();
    store.dispatch(ProcessAudioFileSuccessAction('', tmp));
    return tmp;
  }

  String formatText() {
    String formattedText = this.toUpperCase();

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
    return '[' + formattedText.capitalizeSentences().capitalizeNewLines() + ']';
  }
}

extension DurationExtension on Duration {
  String toAudioDurationString() {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    int hours = this.inHours;
    int minutes = this.inMinutes.remainder(60);
    int seconds = this.inSeconds.remainder(60);

    return hours > 0
        ? "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}"
        : "$minutes:${twoDigits(seconds)}";
  }
}

extension Chunking on List<int> {
  List<List<int>> split(int chunkSize) {
    List<List<int>> chunks = [];
    for (var i = 0; i < this.length; i += chunkSize) {
      final int endIndex = i + chunkSize;
      chunks.add(
          this.sublist(i, endIndex > this.length ? this.length : endIndex));
    }
    return chunks;
  }
}

class HighlightableSpanEditor extends TextEditingController {
  // final Pair<String, double> transcriptTextList;
  static final String BEGIN_FLAG = '[';
  static final String TERMINATING_FLAG = ']';
  final pattern = RegExp(r'\[(.*?)\]');
  String initialText;
  HighlightableSpanEditor(this.initialText) : super(text: initialText);

  void onDoubleTapSpan(int index) {
    store.state.untitled.highlightSpan(index);
  }

  int index = 0;

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    List<InlineSpan> children = [];

    // splitMapJoin is a bit tricky here but i found it very handy for populating children list
    this.text.splitMapJoin(
      pattern,
      onMatch: (Match match) {
        children.add(TextSpan(
            text: match[0],
            recognizer: DoubleTapGestureRecognizer()
              ..onDoubleTap = () => onDoubleTapSpan(index),
            style: style?.merge(
                TextStyle(background: Paint()..color = Colors.greenAccent))));
        this.index++;
        return '';
      },
      onNonMatch: (String text) {
        children.add(TextSpan(text: text, style: style));
        return '';
      },
    );
    this.index = 0;
    return TextSpan(style: style, children: children);
  }
}