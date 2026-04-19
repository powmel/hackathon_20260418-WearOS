class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.displayName,
    required this.score,
    required this.isYou,
  });

  final int rank;
  final String displayName;
  final double score;
  final bool isYou;

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'displayName': displayName,
        'score': score,
        'isYou': isYou,
      };

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      rank: json['rank'] as int? ?? 0,
      displayName: json['displayName'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      isYou: json['isYou'] as bool? ?? false,
    );
  }
}
