import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/app_usage.dart';
import '../services/api_service.dart';

/// SharedPreferences プロバイダー
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

/// ダークモード設定
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DarkModeNotifier(prefs);
});

class DarkModeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  DarkModeNotifier(this._prefs) : super(_prefs.getBool('darkMode') ?? false);

  void toggle() {
    state = !state;
    _prefs.setBool('darkMode', state);
  }
}

/// サイの性格モード
final rhinoModeProvider =
    StateNotifierProvider<RhinoModeNotifier, RhinoMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RhinoModeNotifier(prefs);
});

class RhinoModeNotifier extends StateNotifier<RhinoMode> {
  final SharedPreferences _prefs;

  RhinoModeNotifier(this._prefs)
      : super(
          RhinoMode.values[_prefs.getInt('rhinoMode') ?? 0],
        );

  void setMode(RhinoMode mode) {
    state = mode;
    _prefs.setInt('rhinoMode', mode.index);
  }
}

/// 制限時間（分）
final timeLimitProvider =
    StateNotifierProvider<TimeLimitNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TimeLimitNotifier(prefs);
});

class TimeLimitNotifier extends StateNotifier<int> {
  final SharedPreferences _prefs;

  TimeLimitNotifier(this._prefs)
      : super(_prefs.getInt('timeLimit') ?? defaultTimeLimitMinutes);

  void setLimit(int minutes) {
    state = minutes;
    _prefs.setInt('timeLimit', minutes);
  }
}

/// 通知間隔（分）
final notificationIntervalProvider =
    StateNotifierProvider<NotificationIntervalNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationIntervalNotifier(prefs);
});

class NotificationIntervalNotifier extends StateNotifier<int> {
  final SharedPreferences _prefs;

  NotificationIntervalNotifier(this._prefs)
      : super(_prefs.getInt('notifInterval') ??
            defaultNotificationIntervalMinutes);

  void setInterval(int minutes) {
    state = minutes;
    _prefs.setInt('notifInterval', minutes);
  }
}

/// 通知音 ON/OFF
final soundEnabledProvider =
    StateNotifierProvider<SoundEnabledNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SoundEnabledNotifier(prefs);
});

class SoundEnabledNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  SoundEnabledNotifier(this._prefs)
      : super(_prefs.getBool('soundEnabled') ?? true);

  void toggle() {
    state = !state;
    _prefs.setBool('soundEnabled', state);
  }
}

/// SNS使用時間データ
final usageDataProvider =
    StateNotifierProvider<UsageDataNotifier, List<AppUsageData>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UsageDataNotifier(prefs);
});

class UsageDataNotifier extends StateNotifier<List<AppUsageData>> {
  final SharedPreferences _prefs;

  UsageDataNotifier(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final data = _prefs.getStringList('usageData') ?? [];
    state = data
        .map((e) => AppUsageData.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  void updateUsage(List<AppUsageData> usages) {
    state = usages;
    _save();
  }

  void addUsage(AppUsageData usage) {
    state = [...state, usage];
    _save();
  }

  void _save() {
    final data = state.map((e) => jsonEncode(e.toJson())).toList();
    _prefs.setStringList('usageData', data);
  }
}

/// 制限超過カウント
final overLimitCountProvider =
    StateNotifierProvider<OverLimitCountNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OverLimitCountNotifier(prefs);
});

class OverLimitCountNotifier extends StateNotifier<int> {
  final SharedPreferences _prefs;

  OverLimitCountNotifier(this._prefs)
      : super(_prefs.getInt('overLimitCount_${_todayKey()}') ?? 0);

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  void increment() {
    state++;
    _prefs.setInt('overLimitCount_${_todayKey()}', state);
  }

  void reset() {
    state = 0;
    _prefs.setInt('overLimitCount_${_todayKey()}', 0);
  }
}

/// チャレンジ
final challengeProvider =
    StateNotifierProvider<ChallengeNotifier, List<Challenge>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ChallengeNotifier(prefs);
});

class ChallengeNotifier extends StateNotifier<List<Challenge>> {
  final SharedPreferences _prefs;

  ChallengeNotifier(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final data = _prefs.getStringList('challenges') ?? [];
    state = data
        .map((e) => Challenge.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  void addChallenge(Challenge challenge) {
    state = [...state, challenge];
    _save();
  }

  void updateChallenge(String id, bool isAchieved) {
    state = state.map((c) {
      if (c.id == id) {
        return Challenge(
          id: c.id,
          title: c.title,
          targetTime: c.targetTime,
          date: c.date,
          isAchieved: isAchieved,
        );
      }
      return c;
    }).toList();
    _save();
  }

  void _save() {
    final data = state.map((e) => jsonEncode(e.toJson())).toList();
    _prefs.setStringList('challenges', data);
  }

  /// 連続達成日数
  int get streakDays {
    final achieved = state.where((c) => c.isAchieved).toList();
    if (achieved.isEmpty) return 0;

    achieved.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (final challenge in achieved) {
      final challengeDate = DateTime(
        challenge.date.year,
        challenge.date.month,
        challenge.date.day,
      );
      final check = DateTime(
        checkDate.year,
        checkDate.month,
        checkDate.day,
      );

      if (check.difference(challengeDate).inDays <= 1) {
        streak++;
        checkDate = challengeDate;
      } else {
        break;
      }
    }

    return streak;
  }
}

/// 合計使用時間
final totalUsageProvider = Provider<Duration>((ref) {
  final usages = ref.watch(usageDataProvider);
  if (usages.isEmpty) return Duration.zero;

  final today = DateTime.now();
  final todayUsages = usages.where((u) =>
      u.date.year == today.year &&
      u.date.month == today.month &&
      u.date.day == today.day);

  return todayUsages.fold<Duration>(
    Duration.zero,
    (sum, u) => sum + u.usageTime,
  );
});

/// ユーザー名
final userNameProvider =
    StateNotifierProvider<UserNameNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserNameNotifier(prefs);
});

class UserNameNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  UserNameNotifier(this._prefs) : super(_prefs.getString('userName') ?? '');

  void setName(String name) {
    state = name;
    _prefs.setString('userName', name);
  }
}

/// ユーザー目標
final userGoalProvider =
    StateNotifierProvider<UserGoalNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserGoalNotifier(prefs);
});

class UserGoalNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  UserGoalNotifier(this._prefs) : super(_prefs.getString('userGoal') ?? '');

  void setGoal(String goal) {
    state = goal;
    _prefs.setString('userGoal', goal);
  }
}

/// ユーザーID（匿名・デバイス固有）
final userIdProvider = StateNotifierProvider<UserIdNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserIdNotifier(prefs);
});

class UserIdNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  UserIdNotifier(this._prefs) : super('') {
    final existing = _prefs.getString('userId');
    if (existing != null && existing.isNotEmpty) {
      state = existing;
    } else {
      final newId = 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
      state = newId;
      _prefs.setString('userId', newId);
    }
  }
}

/// 表示名
final displayNameProvider = StateNotifierProvider<DisplayNameNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DisplayNameNotifier(prefs);
});

class DisplayNameNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  DisplayNameNotifier(this._prefs) : super(_prefs.getString('displayName') ?? 'あなた');

  void setName(String name) {
    state = name;
    _prefs.setString('displayName', name);
  }
}

/// ランキングデータ（API経由）
final rankingDataProvider = StateNotifierProvider<RankingDataNotifier, AsyncValue<List<UserRankingData>>>((ref) {
  return RankingDataNotifier();
});

class RankingDataNotifier extends StateNotifier<AsyncValue<List<UserRankingData>>> {
  RankingDataNotifier() : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch({String sortBy = 'efficiencyScore'}) async {
    state = const AsyncValue.loading();
    try {
      final data = await ApiService.getRankings(sortBy: sortBy);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
