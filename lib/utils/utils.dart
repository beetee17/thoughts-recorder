class Pair<T1, T2> {
  final T1 first;
  final T2 second;
  Pair(this.first, this.second);

  @override
  bool operator ==(final Object other) {
    return other is Pair && first == other.first && second == other.second;
  }

  @override
  int get hashCode => Object.hash(first.hashCode, second.hashCode);

  @override
  String toString() => '(${this.first.toString()}, ${this.second.toString()})';
}
