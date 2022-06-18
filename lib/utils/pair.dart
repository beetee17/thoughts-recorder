class Pair<T1, T2> {
  final T1 first;
  final T2 second;
  Pair(this.first, this.second);

  Pair<T1, T2> map(T1 Function(T1) leftMapper, T2 Function(T2) rightMapper) {
    return Pair(leftMapper(first), rightMapper(second));
  }

  Map toJson() => {
        'first': first,
        'second': second,
      };

  Pair.fromJson(Map<String, dynamic> map)
      : first = map['first'],
        second = map['second'];

  @override
  bool operator ==(final Object other) {
    return other is Pair && first == other.first && second == other.second;
  }

  @override
  int get hashCode => Object.hash(first, second);

  @override
  String toString() => '(${first.toString()}, ${second.toString()})';
}
