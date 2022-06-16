import 'dart:io';
import 'dart:math';

import 'package:Minutes/utils/pair.dart';
import 'package:Minutes/utils/transcript_pair.dart';
import 'package:path/path.dart' as path;

extension StringCasingExtension on String {
  String toggleCapitalisation() {
    if (this.isCapitalised()) {
      return this.toLowerCase();
    } else {
      return this.toCapitalized();
    }
  }

  bool isCapitalised() {
    assert(this.length >= 1);
    final regExp = RegExp('[A-Z]');
    return regExp.hasMatch(this.substring(0, 1));
  }

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

extension Filename on File {
  String get name => path.basename(this.path);

  String get nameWithoutExtension => path.basenameWithoutExtension(this.path);

  String get pathWithoutExtension => path.withoutExtension(this.path);

  String get extension => path.extension(this.path);

  Future<File> getNonDuplicate() async {
    int count = 1;
    File candidate = this;
    while (await candidate.exists()) {
      candidate =
          File('${this.pathWithoutExtension} ($count)${this.extension}');
      count++;
    }
    return candidate;
  }
}

extension TextFormatter on String {
  String formatText() {
    String formattedText = this.toUpperCase();

    formattedText = formattedText.replaceAll('COMMA', ',');
    formattedText = formattedText.replaceAll('FULL-STOP', '.');
    formattedText = formattedText.replaceAll('FULL STOP ', '.');

    formattedText = formattedText.replaceAll('PERIOD', '.');
    formattedText = formattedText.replaceAll('QUESTION MARK', '?');
    formattedText = formattedText.replaceAll('EXCLAMATION MARK', '!');
    formattedText = formattedText.replaceAll('SLASH ', '/');

    formattedText = formattedText.replaceAll('NEW LINE', '\n\n');
    formattedText = formattedText.replaceAll('START BRACKET', '(');
    formattedText = formattedText.replaceAll('FINISH BRACKET', ')');

    formattedText = formattedText.replaceAll('START QUOTE', '"');
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

    // Remove whitespace before punctuation marks
    formattedText = formattedText.replaceAllMapped(
        RegExp(r'\s+([.,!":)])'), (Match m) => m.group(1)!);

    return formattedText.capitalizeSentences().capitalizeNewLines();
  }

  String removeSpaceBeforePunctuation() {
    // Remove whitespace before punctuation marks
    return this
        .replaceAllMapped(RegExp(r'\s+([.,!":)])'), (Match m) => m.group(1)!);
  }
}

extension DurationUtils on Duration {
  static Duration min(Duration a, Duration b) {
    return a < b ? a : b;
  }

  static Duration max(Duration a, Duration b) {
    return a > b ? a : b;
  }

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

extension Math on List<Comparable> {
  static Pair<int, T> argmax<T extends Comparable>(List<T> list) {
    T currMax = list.first;
    int currMaxIndex = 0;

    list.asMap().forEach((index, item) {
      if (item.compareTo(currMax) > 0) {
        currMax = item;
        currMaxIndex = index;
      }
    });

    return Pair(currMaxIndex, currMax);
  }
}

extension Safety on List {
  T? getItemAtIf<T>(int index, bool Function(T) cond) {
    if (isEmpty || index < 0 || index >= length) {
      return null;
    }
    if (this[index] == null) {
      return null;
    }
    return cond(this[index]) ? this[index] : null;
  }
}

extension Editor on List<TranscriptPair> {
  List<TranscriptPair> edit(String editedContents, String editedParent) {
    // Initialise empty list
    List<TranscriptPair> result = [];

    // Find the start and end index of the elements that match the parent
    int start = indexWhere((element) => element.parent == editedParent);
    int end = lastIndexWhere((element) => element.parent == editedParent);

    // Split editedContents by space
    Duration startTime =
        firstWhere((element) => element.parent == editedParent).startTime;
    final List<TranscriptPair> editedWords = editedContents
        .split(' ')
        .map((word) => TranscriptPair(word, startTime, editedParent))
        .toList();

    // Copy the sublist of 0..<start
    result.addAll(sublist(0, max(0, start - 1)));

    // addAll(editedWords)
    result.addAll(editedWords);

    // Insert the sublist of end+1..<last
    result.addAll(sublist(end + 1));

    return result;
  }

  List<Pair<String, Pair<String, Duration>>> getMinutes() {
    if (isEmpty) {
      return [];
    }
    List<Pair<String, Pair<String, Duration>>> result = [];

    String currentParent = first.parent;
    String currentMinutes = '';
    int i = 0;
    for (TranscriptPair pair in this) {
      if (pair.parent == currentParent) {
        currentMinutes += pair.word + ' ';
      } else {
        result.add(
            Pair(currentMinutes.trim(), Pair(currentParent, pair.startTime)));
        currentParent = pair.parent;
        currentMinutes = pair.word + ' ';
      }
    }

    return result;
  }
}
