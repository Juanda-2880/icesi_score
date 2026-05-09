class MatchException implements Exception {
  final String message;
  const MatchException(this.message);

  @override
  String toString() => message;
}
