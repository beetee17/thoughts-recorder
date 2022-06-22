import 'dart:convert';

import 'package:Minutes/utils/extensions.dart';
import 'package:Minutes/utils/global_variables.dart';
import 'package:Minutes/utils/pair.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class TranscriptPair {
  final String word;
  final String
      parent; // TranscriptPairs with the same startTime should share the same minutesIndex
  final Duration startTime;
  final Pair<int, double>? punctuationData;

  TranscriptPair(
      {required this.word,
      required this.startTime,
      required this.parent,
      required this.punctuationData});

  String get punctuated {
    if (punctuationData == null || word.isEmpty) {
      return word;
    }

    // We want to take care of potential whitespace before/after word
    // E.g. if punctuation is , and word is ' hi \n', we want ' hi, \n' and not ' hi \n,'
    String result = '';
    int? start; // index of first non-whitespace char
    int? end; // index of last non-whitespace char

    for (int i = 0; i < word.length; i++) {
      final String char = word[i];
      if (!invalidCharacters.hasMatch(char)) {
        result += char;
        start = start ?? i;
      } else if (start != null) {
        end = i;
        break;
      }
    }

    if (result.isEmpty) {
      return result;
    }

    final String punctuation = punctuationMap[punctuationData!.first] ?? 'OO';

    if (punctuation[0] != 'O') {
      // If user already added punctuation we do not want to append to that
      // E.g. if word is 'hello.' and punctuation is ? then we want 'hello?' and not 'hello.?'
      if (punctuationCharacters.hasMatch(result[result.length - 1])) {
        result = result.substring(0, result.length - 1) + punctuation[0];
      } else {
        result += punctuation[0];
      }
    } else if (punctuationCharacters.hasMatch(result[result.length - 1])) {
      // If the suggestion is no punctuation but the user added puncutation, then the suggestion is to remove it
      result = result.substring(0, result.length - 1);
    }

    if (punctuation[1] == 'U') {
      result = result.toCapitalized();
    } else if (result.isCapitalised()) {
      result = result.toLowerCase();
    }

    if (end == null) {
      return word.substring(0, start) + result;
    }
    // The only reason start and end can both be null is if word is only whitespaces
    return word.substring(0, start) + result + word.substring(end);
  }

  TranscriptPair mapWord(String Function(String) textMapper) {
    return TranscriptPair(
      word: textMapper(word),
      startTime: startTime,
      parent: parent,
      punctuationData: punctuationData,
    );
  }

  TranscriptPair copyWith({
    final String? word,
    final String? parent,
    final Duration? startTime,
    final Pair<int, double>? punctuationData,
    final bool shouldOverrideData = false,
  }) {
    return TranscriptPair(
      word: word ?? this.word,
      parent: parent ?? this.parent,
      startTime: startTime ?? this.startTime,
      punctuationData:
          shouldOverrideData ? punctuationData : this.punctuationData,
    );
  }

  Map toJson() => {
        'word': word,
        'startTime': startTime.inMilliseconds,
        'parent': parent,
        'punctuationData': punctuationData,
      };

  TranscriptPair.fromJson(Map<String, dynamic> map)
      : word = map['word'],
        startTime = Duration(milliseconds: map['startTime']),
        parent = map['parent'],
        punctuationData = map['punctuationData'] == null
            ? null
            : Pair.fromJson(map['punctuationData']);

  @override
  bool operator ==(final Object other) {
    return other is TranscriptPair &&
        word == other.word &&
        startTime == other.startTime &&
        parent == other.parent &&
        punctuationData == other.punctuationData;
  }

  @override
  int get hashCode => Object.hash(word, startTime, parent, punctuationData);

  @override
  String toString() =>
      '$parent: (${word.toString()}, ${startTime.inMilliseconds}ms, $punctuationData)';
}
