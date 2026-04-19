enum PetMood {
  happy('楽しそう', '集中できていて上機嫌'),
  calm('ふつう', '落ち着いて見守り中'),
  sad('泣きそう', '使いすぎでしょんぼり');

  const PetMood(this.label, this.detail);
  final String label;
  final String detail;
}

enum PetOutfit {
  none('そのまま'),
  cape('ケープ'),
  bow('リボン'),
  raincoat('レイン');

  const PetOutfit(this.label);
  final String label;
}

class PetState {
  const PetState({
    required this.focusScore,
    required this.usageMinutes,
    required this.fullness,
    required this.mood,
    required this.outfit,
  });

  final int focusScore;
  final int usageMinutes;
  final int fullness;
  final PetMood mood;
  final PetOutfit outfit;

  Map<String, dynamic> toJson() => {
        'focusScore': focusScore,
        'usageMinutes': usageMinutes,
        'fullness': fullness,
        'mood': mood.name,
        'outfit': outfit.name,
      };

  factory PetState.fromJson(Map<String, dynamic> json) {
    return PetState(
      focusScore: json['focusScore'] as int? ?? 0,
      usageMinutes: json['usageMinutes'] as int? ?? 0,
      fullness: json['fullness'] as int? ?? 50,
      mood: PetMood.values.byName(json['mood'] as String? ?? 'calm'),
      outfit: PetOutfit.values.byName(json['outfit'] as String? ?? 'none'),
    );
  }
}
