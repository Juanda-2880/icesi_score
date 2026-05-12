class VolleyballSet {
  final String id;
  final int setNumber;
  final int homeScore;
  final int awayScore;
  final bool isActive;
  final String? endTime;

  const VolleyballSet({
    required this.id,
    required this.setNumber,
    required this.homeScore,
    required this.awayScore,
    required this.isActive,
    this.endTime,
  });
}
