/// SNSアプリの使用時間データモデル
class AppUsageData {
  final String packageName;
  final String appName;
  final Duration usageTime;
  final DateTime date;

  const AppUsageData({
    required this.packageName,
    required this.appName,
    required this.usageTime,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'appName': appName,
        'usageTimeMinutes': usageTime.inMinutes,
        'date': date.toIso8601String(),
      };

  factory AppUsageData.fromJson(Map<String, dynamic> json) => AppUsageData(
        packageName: json['packageName'] as String,
        appName: json['appName'] as String,
        usageTime: Duration(minutes: json['usageTimeMinutes'] as int),
        date: DateTime.parse(json['date'] as String),
      );
}

/// 個別セッション（1回のアプリ起動〜終了）
class UsageSession {
  final String packageName;
  final String appName;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;

  const UsageSession({
    required this.packageName,
    required this.appName,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'appName': appName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationSeconds': duration.inSeconds,
      };

  factory UsageSession.fromJson(Map<String, dynamic> json) => UsageSession(
        packageName: json['packageName'] as String,
        appName: json['appName'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        duration: Duration(seconds: json['durationSeconds'] as int),
      );
}

/// 日次集計サマリー
class DailyUsageSummary {
  final DateTime date;
  final int totalMinutes;
  final int sessionCount;
  final int overLimitCount;
  final Map<String, int> appMinutes; // packageName -> minutes
  final Map<String, int> appSessionCounts; // packageName -> count
  final Map<int, int> hourlyMinutes; // hour (0-23) -> minutes

  const DailyUsageSummary({
    required this.date,
    required this.totalMinutes,
    required this.sessionCount,
    required this.overLimitCount,
    required this.appMinutes,
    required this.appSessionCounts,
    required this.hourlyMinutes,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'totalMinutes': totalMinutes,
        'sessionCount': sessionCount,
        'overLimitCount': overLimitCount,
        'appMinutes': appMinutes,
        'appSessionCounts': appSessionCounts,
        'hourlyMinutes':
            hourlyMinutes.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory DailyUsageSummary.fromJson(Map<String, dynamic> json) =>
      DailyUsageSummary(
        date: DateTime.parse(json['date'] as String),
        totalMinutes: json['totalMinutes'] as int,
        sessionCount: json['sessionCount'] as int,
        overLimitCount: json['overLimitCount'] as int,
        appMinutes: Map<String, int>.from(json['appMinutes'] as Map),
        appSessionCounts:
            Map<String, int>.from(json['appSessionCounts'] as Map),
        hourlyMinutes: (json['hourlyMinutes'] as Map)
            .map((k, v) => MapEntry(int.parse(k.toString()), v as int)),
      );
}

/// 日次レポートデータ
class DailyReport {
  final DateTime date;
  final List<AppUsageData> appUsages;
  final int overLimitCount;
  final Duration totalUsage;
  final Duration savedTime;

  const DailyReport({
    required this.date,
    required this.appUsages,
    required this.overLimitCount,
    required this.totalUsage,
    required this.savedTime,
  });
}

/// ランキング用ユーザーデータ
class UserRankingData {
  final String userId;
  final String displayName;
  final int weeklyTotalMinutes;
  final int streakDays;
  final double efficiencyScore;

  const UserRankingData({
    required this.userId,
    required this.displayName,
    required this.weeklyTotalMinutes,
    required this.streakDays,
    required this.efficiencyScore,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'weeklyTotalMinutes': weeklyTotalMinutes,
        'streakDays': streakDays,
        'efficiencyScore': efficiencyScore,
      };

  factory UserRankingData.fromJson(Map<String, dynamic> json) =>
      UserRankingData(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String,
        weeklyTotalMinutes: json['weeklyTotalMinutes'] as int,
        streakDays: json['streakDays'] as int,
        efficiencyScore: (json['efficiencyScore'] as num).toDouble(),
      );
}

/// チャレンジデータ
class Challenge {
  final String id;
  final String title;
  final Duration targetTime;
  final DateTime date;
  final bool isAchieved;

  const Challenge({
    required this.id,
    required this.title,
    required this.targetTime,
    required this.date,
    required this.isAchieved,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetTimeMinutes': targetTime.inMinutes,
        'date': date.toIso8601String(),
        'isAchieved': isAchieved,
      };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'] as String,
        title: json['title'] as String,
        targetTime: Duration(minutes: json['targetTimeMinutes'] as int),
        date: DateTime.parse(json['date'] as String),
        isAchieved: json['isAchieved'] as bool,
      );
}
