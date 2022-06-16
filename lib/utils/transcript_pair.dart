import 'package:uuid/uuid.dart';

class TranscriptPair {
  final String word;
  final String
      parent; // TranscriptPairs with the same startTime should share the same minutesIndex
  final Duration startTime;
  TranscriptPair(this.word, this.startTime, this.parent);

  TranscriptPair copyWith(String Function(String) textMapper) {
    return TranscriptPair(textMapper(word), startTime, parent);
  }

  Map toJson() =>
      {'word': word, 'startTime': startTime.inMilliseconds, 'parent': parent};

  TranscriptPair.fromJson(Map<String, dynamic> map)
      : word = map['word'],
        startTime = Duration(milliseconds: map['startTime']),
        parent = map['parent'];

  @override
  bool operator ==(final Object other) {
    return other is TranscriptPair &&
        word == other.word &&
        startTime == other.startTime &&
        parent == other.parent;
  }

  @override
  int get hashCode => Object.hash(word, startTime, parent);

  @override
  String toString() =>
      '$parent: (${word.toString()}, ${startTime.toString()}ms)';
}
