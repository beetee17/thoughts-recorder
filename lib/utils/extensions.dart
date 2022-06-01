import 'package:leopard_demo/redux_/rootStore.dart';
import 'package:leopard_demo/redux_/untitled.dart';
import 'package:leopard_demo/utils/pair.dart';

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
  static final RegExp GET_ALL_BETWEEN_PATTERN = RegExp(r'\[(.*?)\]');
  // match group 0 is inclusive, match group 1 is exclusive of []
  static List<Pair<String, double>> updateTranscriptTextList(
      String editedText, List<Pair<String, double>> transcriptTextList) {
    List<Pair<String, double>> res = [];
    int index = 0;
    editedText.splitMapJoin(
      GET_ALL_BETWEEN_PATTERN,
      onMatch: (Match match) {
        print(match.group(0));
        res.add(transcriptTextList[index]
            .map((left) => match.group(0)!, (right) => right));
        index++;
        return '';
      },
    );
    store.dispatch(UpdateTranscriptTextList(res));

    return res;
  }

  static List<Pair<String, double>> formatTextList(
      List<Pair<String, double>> transcriptTextList) {
    final tmp = transcriptTextList
        .map((pair) =>
            pair.map((first) => first.formatText(), (second) => second))
        .toList();
    return tmp;
  }

  String formatText() {
    String? match = GET_ALL_BETWEEN_PATTERN.firstMatch(this)?.group(1);
    if (match == null) {
      return '';
    }
    String formattedText = match.toUpperCase();
    print(formattedText);
    formattedText = formattedText.replaceAll(' COMMA', ',');
    formattedText = formattedText.replaceAll(' FULL-STOP', '.');
    formattedText = formattedText.replaceAll(' FULL STOP', '.');
    formattedText = formattedText.replaceAll('FULL-STOP', '.');
    formattedText = formattedText.replaceAll('FULL STOP ', '.');
    formattedText = formattedText.replaceAll('NEW LINE ', '\n\n');
    formattedText = formattedText.replaceAll('NEW LINE', '\n\n');

    formattedText = formattedText.replaceAll(' PERIOD', '.');
    formattedText = formattedText.replaceAll(' SLASH ', '/');
    formattedText = formattedText.replaceAll('PERIOD', '.');
    formattedText = formattedText.replaceAll('SLASH ', '/');

    formattedText = formattedText.replaceAll('AMPERSAND', '&');
    formattedText = formattedText.replaceAll('START BRACKET', '(');
    formattedText = formattedText.replaceAll(' FINISH BRACKET', ')');
    formattedText = formattedText.replaceAll('FINISH BRACKET', ')');

    formattedText = formattedText.replaceAll('START QUOTE', '"');
    formattedText = formattedText.replaceAll(' FINISH QUOTE', '"');
    formattedText = formattedText.replaceAll('FINISH QUOTE', '"');

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
