import 'package:Minutes/utils/global_variables.dart';
import 'package:Minutes/utils/pair.dart';
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
    final String punctuation = punctuationMap[punctuationData?.first] ?? '';
    return word + punctuation;
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
        punctuationData = map['punctuationData'];

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
