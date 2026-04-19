import 'dart:math';
import '../models/app_usage.dart';

/// 統計分析結果を格納するクラス群

/// 記述統計量
class DescriptiveStats {
  final double mean;
  final double median;
  final double standardDeviation;
  final double variance;
  final double min;
  final double max;
  final double q1; // 第1四分位数
  final double q3; // 第3四分位数
  final double iqr; // 四分位範囲
  final double skewness; // 歪度
  final int count;

  const DescriptiveStats({
    required this.mean,
    required this.median,
    required this.standardDeviation,
    required this.variance,
    required this.min,
    required this.max,
    required this.q1,
    required this.q3,
    required this.iqr,
    required this.skewness,
    required this.count,
  });
}

/// トレンド分析結果
class TrendAnalysis {
  final double slope; // 回帰直線の傾き（分/日）
  final double intercept; // 切片
  final double rSquared; // 決定係数 R²
  final String trendDirection; // "increasing", "decreasing", "stable"
  final double predictedTomorrow; // 明日の予測値
  final List<double> movingAverage; // 移動平均

  const TrendAnalysis({
    required this.slope,
    required this.intercept,
    required this.rSquared,
    required this.trendDirection,
    required this.predictedTomorrow,
    required this.movingAverage,
  });
}

/// 曜日別パターン分析
class DayOfWeekPattern {
  final Map<int, double> averageByDay; // 1=月 ~ 7=日
  final int peakDay; // 最も使用時間が多い曜日
  final int lowDay; // 最も少ない曜日
  final double weekdayAverage; // 平日平均
  final double weekendAverage; // 休日平均
  final double weekendEffect; // 休日効果 (%)

  const DayOfWeekPattern({
    required this.averageByDay,
    required this.peakDay,
    required this.lowDay,
    required this.weekdayAverage,
    required this.weekendAverage,
    required this.weekendEffect,
  });
}

/// 時間帯別パターン分析
class HourlyPattern {
  final Map<int, double> averageByHour; // 0-23
  final int peakHour;
  final int lowHour;
  final double morningTotal; // 6-11
  final double afternoonTotal; // 12-17
  final double eveningTotal; // 18-23
  final double nightTotal; // 0-5

  const HourlyPattern({
    required this.averageByHour,
    required this.peakHour,
    required this.lowHour,
    required this.morningTotal,
    required this.afternoonTotal,
    required this.eveningTotal,
    required this.nightTotal,
  });
}

/// 異常値検出結果
class AnomalyDetection {
  final List<AnomalyPoint> anomalies;
  final double upperBound; // 上限 (μ + 2σ)
  final double lowerBound; // 下限 (μ - 2σ)

  const AnomalyDetection({
    required this.anomalies,
    required this.upperBound,
    required this.lowerBound,
  });
}

class AnomalyPoint {
  final DateTime date;
  final double value;
  final double zScore;
  final String type; // "high" or "low"

  const AnomalyPoint({
    required this.date,
    required this.value,
    required this.zScore,
    required this.type,
  });
}

/// セッション分析結果
class SessionAnalysis {
  final DescriptiveStats sessionDurationStats; // セッション時間の統計
  final DescriptiveStats sessionCountStats; // セッション回数の統計
  final double avgSessionsPerDay;
  final double avgSessionDurationMinutes;
  final String usagePattern; // "binge"(長時間少回数), "frequent"(短時間多回数), "balanced"

  const SessionAnalysis({
    required this.sessionDurationStats,
    required this.sessionCountStats,
    required this.avgSessionsPerDay,
    required this.avgSessionDurationMinutes,
    required this.usagePattern,
  });
}

/// 相関分析結果
class CorrelationResult {
  final String factorA;
  final String factorB;
  final double pearsonR; // ピアソン相関係数
  final String strength; // "strong", "moderate", "weak", "none"
  final String direction; // "positive", "negative"

  const CorrelationResult({
    required this.factorA,
    required this.factorB,
    required this.pearsonR,
    required this.strength,
    required this.direction,
  });
}

/// 総合分析レポート
class AnalyticsReport {
  final DescriptiveStats overallStats;
  final TrendAnalysis trend;
  final DayOfWeekPattern dayOfWeekPattern;
  final HourlyPattern hourlyPattern;
  final AnomalyDetection anomalies;
  final SessionAnalysis sessionAnalysis;
  final List<CorrelationResult> correlations;
  final Map<String, DescriptiveStats> perAppStats;
  final double healthScore; // 0-100 総合スコア
  final List<String> insights; // 自動生成されたインサイト文

  const AnalyticsReport({
    required this.overallStats,
    required this.trend,
    required this.dayOfWeekPattern,
    required this.hourlyPattern,
    required this.anomalies,
    required this.sessionAnalysis,
    required this.correlations,
    required this.perAppStats,
    required this.healthScore,
    required this.insights,
  });
}

/// データサイエンス分析エンジン
class AnalyticsService {
  /// デモ用：過去N日分のダミーデータを生成
  /// DB接続後はここをDynamoDB/AppSyncからのフェッチに差し替える
  static List<DailyUsageSummary> generateDemoData({int days = 30}) {
    final random = Random(42); // 再現性のためシード固定
    final now = DateTime.now();
    final data = <DailyUsageSummary>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

      // 基本使用時間: 平日30-80分、休日50-120分 + トレンド（徐々に減少）
      final baseLine = isWeekend ? 85.0 : 55.0;
      final trendEffect = -0.5 * (days - i); // 日が経つにつれ減少傾向
      final noise = (random.nextDouble() - 0.5) * 40;
      final totalMin =
          (baseLine + trendEffect + noise).clamp(5, 180).round();

      // アプリ別配分
      final instaPct = 0.35 + (random.nextDouble() - 0.5) * 0.15;
      final twitterPct = 0.35 + (random.nextDouble() - 0.5) * 0.15;
      final tiktokPct = 1.0 - instaPct - twitterPct;

      final instaMin = (totalMin * instaPct).round();
      final twitterMin = (totalMin * twitterPct).round();
      final tiktokMin = (totalMin * tiktokPct).round();

      // セッション数: 使用時間が多いほどセッション数も多い傾向
      final sessionCount =
          (totalMin / 8 + random.nextInt(5)).clamp(1, 30).round();

      // 時間帯別使用（ピークは夜）
      final hourly = <int, int>{};
      final hourWeights = [
        1, 1, 0, 0, 0, 0, // 0-5: 深夜
        2, 3, 3, 2, 2, 3, // 6-11: 朝
        4, 4, 3, 3, 3, 4, // 12-17: 昼
        5, 6, 7, 8, 6, 3, // 18-23: 夜（ピーク）
      ];
      final totalWeight = hourWeights.reduce((a, b) => a + b);
      for (int h = 0; h < 24; h++) {
        final mins = (totalMin * hourWeights[h] / totalWeight +
                (random.nextDouble() - 0.5) * 2)
            .clamp(0, 30)
            .round();
        if (mins > 0) hourly[h] = mins;
      }

      // 制限超過回数
      final overLimit = totalMin > 60 ? random.nextInt(3) + 1 : 0;

      data.add(DailyUsageSummary(
        date: DateTime(date.year, date.month, date.day),
        totalMinutes: totalMin,
        sessionCount: sessionCount,
        overLimitCount: overLimit,
        appMinutes: {
          'com.instagram.android': instaMin,
          'com.twitter.android': twitterMin,
          'com.zhiliaoapp.musically': tiktokMin,
        },
        appSessionCounts: {
          'com.instagram.android': (sessionCount * instaPct).round().clamp(1, 20),
          'com.twitter.android': (sessionCount * twitterPct).round().clamp(1, 20),
          'com.zhiliaoapp.musically':
              (sessionCount * tiktokPct).round().clamp(1, 20),
        },
        hourlyMinutes: hourly,
      ));
    }
    return data;
  }

  /// 総合分析レポートを生成
  static AnalyticsReport analyze(
    List<DailyUsageSummary> dailyData, {
    int timeLimit = 30,
  }) {
    if (dailyData.isEmpty) {
      return _emptyReport();
    }

    final totalMinutesList =
        dailyData.map((d) => d.totalMinutes.toDouble()).toList();

    // 1. 記述統計量
    final overallStats = _computeDescriptiveStats(totalMinutesList);

    // 2. トレンド分析（線形回帰 + 移動平均）
    final trend = _computeTrend(totalMinutesList);

    // 3. 曜日別パターン
    final dayPattern = _computeDayOfWeekPattern(dailyData);

    // 4. 時間帯別パターン
    final hourlyPattern = _computeHourlyPattern(dailyData);

    // 5. 異常値検出（Z-score法）
    final anomalies = _detectAnomalies(dailyData, overallStats);

    // 6. セッション分析
    final sessionAnalysis = _analyzeSession(dailyData);

    // 7. 相関分析
    final correlations = _computeCorrelations(dailyData);

    // 8. アプリ別統計
    final perAppStats = _computePerAppStats(dailyData);

    // 9. ヘルススコア算出
    final healthScore =
        _computeHealthScore(overallStats, trend, sessionAnalysis, timeLimit);

    // 10. インサイト自動生成
    final insights = _generateInsights(
      overallStats,
      trend,
      dayPattern,
      hourlyPattern,
      anomalies,
      sessionAnalysis,
      correlations,
      timeLimit,
    );

    return AnalyticsReport(
      overallStats: overallStats,
      trend: trend,
      dayOfWeekPattern: dayPattern,
      hourlyPattern: hourlyPattern,
      anomalies: anomalies,
      sessionAnalysis: sessionAnalysis,
      correlations: correlations,
      perAppStats: perAppStats,
      healthScore: healthScore,
      insights: insights,
    );
  }

  // ========== 記述統計量 ==========
  static DescriptiveStats _computeDescriptiveStats(List<double> values) {
    if (values.isEmpty) return _emptyStats();
    final n = values.length;
    final sorted = List<double>.from(values)..sort();

    final mean = values.reduce((a, b) => a + b) / n;
    final median = _percentile(sorted, 50);
    final q1 = _percentile(sorted, 25);
    final q3 = _percentile(sorted, 75);
    final iqr = q3 - q1;

    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / n;
    final sd = sqrt(variance);

    // 歪度 (Fisher-Pearson)
    double skewness = 0;
    if (sd > 0 && n > 2) {
      final m3 =
          values.map((v) => pow(v - mean, 3)).reduce((a, b) => a + b) / n;
      skewness = m3 / pow(sd, 3);
    }

    return DescriptiveStats(
      mean: mean,
      median: median,
      standardDeviation: sd,
      variance: variance,
      min: sorted.first,
      max: sorted.last,
      q1: q1,
      q3: q3,
      iqr: iqr,
      skewness: skewness,
      count: n,
    );
  }

  static double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0;
    if (sorted.length == 1) return sorted[0];
    final index = (p / 100) * (sorted.length - 1);
    final lower = index.floor();
    final upper = index.ceil();
    if (lower == upper) return sorted[lower];
    return sorted[lower] + (sorted[upper] - sorted[lower]) * (index - lower);
  }

  // ========== トレンド分析 (最小二乗法 + 移動平均) ==========
  static TrendAnalysis _computeTrend(List<double> values) {
    if (values.length < 2) {
      return TrendAnalysis(
        slope: 0,
        intercept: values.isEmpty ? 0 : values[0],
        rSquared: 0,
        trendDirection: 'stable',
        predictedTomorrow: values.isEmpty ? 0 : values[0],
        movingAverage: values,
      );
    }

    final n = values.length;

    // 単純線形回帰 y = a + bx
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i;
    }
    final meanX = sumX / n;
    final meanY = sumY / n;
    final slope = (sumXY - n * meanX * meanY) / (sumX2 - n * meanX * meanX);
    final intercept = meanY - slope * meanX;

    // R² (決定係数)
    double ssTot = 0, ssRes = 0;
    for (int i = 0; i < n; i++) {
      final predicted = intercept + slope * i;
      ssTot += pow(values[i] - meanY, 2);
      ssRes += pow(values[i] - predicted, 2);
    }
    final rSquared = ssTot > 0 ? 1 - (ssRes / ssTot) : 0.0;

    // トレンド方向の判定
    String direction;
    if (slope.abs() < 0.3) {
      direction = 'stable';
    } else if (slope > 0) {
      direction = 'increasing';
    } else {
      direction = 'decreasing';
    }

    // 7日移動平均
    final window = min(7, n);
    final ma = <double>[];
    for (int i = 0; i < n; i++) {
      final start = max(0, i - window + 1);
      final subset = values.sublist(start, i + 1);
      ma.add(subset.reduce((a, b) => a + b) / subset.length);
    }

    final predicted = intercept + slope * n;

    return TrendAnalysis(
      slope: slope,
      intercept: intercept,
      rSquared: rSquared,
      trendDirection: direction,
      predictedTomorrow: predicted.clamp(0, 300),
      movingAverage: ma,
    );
  }

  // ========== 曜日別パターン ==========
  static DayOfWeekPattern _computeDayOfWeekPattern(
      List<DailyUsageSummary> data) {
    final byDay = <int, List<double>>{};
    for (int d = 1; d <= 7; d++) {
      byDay[d] = [];
    }

    for (final day in data) {
      byDay[day.date.weekday]!.add(day.totalMinutes.toDouble());
    }

    final avgByDay = <int, double>{};
    for (final entry in byDay.entries) {
      if (entry.value.isEmpty) {
        avgByDay[entry.key] = 0;
      } else {
        avgByDay[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }

    final peakDay = avgByDay.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    final lowDay = avgByDay.entries
        .reduce((a, b) => a.value <= b.value ? a : b)
        .key;

    // 平日 (月-金) vs 週末 (土日)
    final weekdayValues = <double>[];
    final weekendValues = <double>[];
    for (final day in data) {
      if (day.date.weekday >= 6) {
        weekendValues.add(day.totalMinutes.toDouble());
      } else {
        weekdayValues.add(day.totalMinutes.toDouble());
      }
    }

    final weekdayAvg = weekdayValues.isEmpty
        ? 0.0
        : weekdayValues.reduce((a, b) => a + b) / weekdayValues.length;
    final weekendAvg = weekendValues.isEmpty
        ? 0.0
        : weekendValues.reduce((a, b) => a + b) / weekendValues.length;
    final weekendEffect =
        weekdayAvg > 0 ? ((weekendAvg - weekdayAvg) / weekdayAvg * 100) : 0.0;

    return DayOfWeekPattern(
      averageByDay: avgByDay,
      peakDay: peakDay,
      lowDay: lowDay,
      weekdayAverage: weekdayAvg,
      weekendAverage: weekendAvg,
      weekendEffect: weekendEffect,
    );
  }

  // ========== 時間帯別パターン ==========
  static HourlyPattern _computeHourlyPattern(List<DailyUsageSummary> data) {
    final hourlySum = <int, double>{};
    final hourlyCounts = <int, int>{};
    for (int h = 0; h < 24; h++) {
      hourlySum[h] = 0;
      hourlyCounts[h] = 0;
    }

    for (final day in data) {
      for (final entry in day.hourlyMinutes.entries) {
        hourlySum[entry.key] = (hourlySum[entry.key] ?? 0) + entry.value;
        hourlyCounts[entry.key] = (hourlyCounts[entry.key] ?? 0) + 1;
      }
    }

    final avgByHour = <int, double>{};
    for (int h = 0; h < 24; h++) {
      avgByHour[h] = hourlyCounts[h]! > 0
          ? hourlySum[h]! / data.length
          : 0;
    }

    final peakHour =
        avgByHour.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final lowHour =
        avgByHour.entries.reduce((a, b) => a.value <= b.value ? a : b).key;

    double morning = 0, afternoon = 0, evening = 0, night = 0;
    for (int h = 0; h < 24; h++) {
      final v = avgByHour[h]!;
      if (h >= 6 && h < 12) {
        morning += v;
      } else if (h >= 12 && h < 18) {
        afternoon += v;
      } else if (h >= 18) {
        evening += v;
      } else {
        night += v;
      }
    }

    return HourlyPattern(
      averageByHour: avgByHour,
      peakHour: peakHour,
      lowHour: lowHour,
      morningTotal: morning,
      afternoonTotal: afternoon,
      eveningTotal: evening,
      nightTotal: night,
    );
  }

  // ========== 異常値検出 (Zスコア法) ==========
  static AnomalyDetection _detectAnomalies(
      List<DailyUsageSummary> data, DescriptiveStats stats) {
    final anomalies = <AnomalyPoint>[];
    final threshold = 2.0; // |z| > 2 で異常値

    final upperBound = stats.mean + threshold * stats.standardDeviation;
    final lowerBound = stats.mean - threshold * stats.standardDeviation;

    if (stats.standardDeviation > 0) {
      for (final day in data) {
        final z = (day.totalMinutes - stats.mean) / stats.standardDeviation;
        if (z.abs() > threshold) {
          anomalies.add(AnomalyPoint(
            date: day.date,
            value: day.totalMinutes.toDouble(),
            zScore: z,
            type: z > 0 ? 'high' : 'low',
          ));
        }
      }
    }

    return AnomalyDetection(
      anomalies: anomalies,
      upperBound: upperBound,
      lowerBound: lowerBound.clamp(0, double.infinity),
    );
  }

  // ========== セッション分析 ==========
  static SessionAnalysis _analyzeSession(List<DailyUsageSummary> data) {
    final sessionCounts =
        data.map((d) => d.sessionCount.toDouble()).toList();
    final avgDurations = data
        .map((d) => d.sessionCount > 0
            ? d.totalMinutes.toDouble() / d.sessionCount
            : 0.0)
        .toList();

    final countStats = _computeDescriptiveStats(sessionCounts);
    final durationStats = _computeDescriptiveStats(avgDurations);

    final avgSessions = countStats.mean;
    final avgDuration = durationStats.mean;

    // 使用パターン分類
    String pattern;
    if (avgDuration > 10 && avgSessions < 5) {
      pattern = 'binge'; // 長時間・少回数 → 依存的
    } else if (avgDuration < 5 && avgSessions > 10) {
      pattern = 'frequent'; // 短時間・多回数 → 衝動的
    } else {
      pattern = 'balanced';
    }

    return SessionAnalysis(
      sessionDurationStats: durationStats,
      sessionCountStats: countStats,
      avgSessionsPerDay: avgSessions,
      avgSessionDurationMinutes: avgDuration,
      usagePattern: pattern,
    );
  }

  // ========== 相関分析 (ピアソン相関係数) ==========
  static List<CorrelationResult> _computeCorrelations(
      List<DailyUsageSummary> data) {
    if (data.length < 3) return [];

    final results = <CorrelationResult>[];

    // 1. 使用時間 vs セッション回数
    final minutes = data.map((d) => d.totalMinutes.toDouble()).toList();
    final sessions = data.map((d) => d.sessionCount.toDouble()).toList();
    results.add(_pearsonCorrelation(
      minutes, sessions, '使用時間(分)', 'セッション回数',
    ));

    // 2. 使用時間 vs 制限超過回数
    final overLimits = data.map((d) => d.overLimitCount.toDouble()).toList();
    results.add(_pearsonCorrelation(
      minutes, overLimits, '使用時間(分)', '制限超過回数',
    ));

    // 3. セッション回数 vs 制限超過回数
    results.add(_pearsonCorrelation(
      sessions, overLimits, 'セッション回数', '制限超過回数',
    ));

    // 4. 曜日番号 vs 使用時間
    final weekdays = data.map((d) => d.date.weekday.toDouble()).toList();
    results.add(_pearsonCorrelation(
      weekdays, minutes, '曜日(1=月〜7=日)', '使用時間(分)',
    ));

    return results;
  }

  static CorrelationResult _pearsonCorrelation(
      List<double> x, List<double> y, String nameA, String nameB) {
    final n = x.length;
    if (n < 2) {
      return CorrelationResult(
        factorA: nameA,
        factorB: nameB,
        pearsonR: 0,
        strength: 'none',
        direction: 'positive',
      );
    }

    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;

    double sumXY = 0, sumX2 = 0, sumY2 = 0;
    for (int i = 0; i < n; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      sumXY += dx * dy;
      sumX2 += dx * dx;
      sumY2 += dy * dy;
    }

    final denom = sqrt(sumX2 * sumY2);
    final r = denom > 0 ? sumXY / denom : 0.0;

    String strength;
    final absR = r.abs();
    if (absR >= 0.7) {
      strength = 'strong';
    } else if (absR >= 0.4) {
      strength = 'moderate';
    } else if (absR >= 0.2) {
      strength = 'weak';
    } else {
      strength = 'none';
    }

    return CorrelationResult(
      factorA: nameA,
      factorB: nameB,
      pearsonR: r,
      strength: strength,
      direction: r >= 0 ? 'positive' : 'negative',
    );
  }

  // ========== アプリ別統計 ==========
  static Map<String, DescriptiveStats> _computePerAppStats(
      List<DailyUsageSummary> data) {
    final appData = <String, List<double>>{};

    for (final day in data) {
      for (final entry in day.appMinutes.entries) {
        appData.putIfAbsent(entry.key, () => []);
        appData[entry.key]!.add(entry.value.toDouble());
      }
    }

    return appData
        .map((key, values) => MapEntry(key, _computeDescriptiveStats(values)));
  }

  // ========== ヘルススコア算出 ==========
  static double _computeHealthScore(
    DescriptiveStats stats,
    TrendAnalysis trend,
    SessionAnalysis session,
    int timeLimit,
  ) {
    double score = 100;

    // 1. 平均使用時間が制限を超えているほど減点 (-30点まで)
    final overRatio = stats.mean / timeLimit;
    if (overRatio > 1.0) {
      score -= min(30, (overRatio - 1.0) * 30);
    }

    // 2. トレンドが増加傾向なら減点 (-20点まで)
    if (trend.trendDirection == 'increasing') {
      score -= min(20, trend.slope.abs() * 10);
    } else if (trend.trendDirection == 'decreasing') {
      score += min(10, trend.slope.abs() * 5); // 減少なら加点
    }

    // 3. ばらつきが大きいほど減点 (-15点まで)
    final cvPercent = stats.mean > 0
        ? (stats.standardDeviation / stats.mean * 100)
        : 0;
    if (cvPercent > 50) {
      score -= min(15, (cvPercent - 50) * 0.5);
    }

    // 4. binge型パターンなら減点
    if (session.usagePattern == 'binge') {
      score -= 15;
    } else if (session.usagePattern == 'frequent') {
      score -= 10;
    }

    // 5. 異常値の頻度で減点
    // (anomalies count is incorporated via other scores)

    return score.clamp(0, 100);
  }

  // ========== インサイト自動生成 ==========
  static List<String> _generateInsights(
    DescriptiveStats stats,
    TrendAnalysis trend,
    DayOfWeekPattern dayPattern,
    HourlyPattern hourly,
    AnomalyDetection anomalies,
    SessionAnalysis session,
    List<CorrelationResult> correlations,
    int timeLimit,
  ) {
    final insights = <String>[];

    // トレンド → わかりやすい表現
    if (trend.trendDirection == 'decreasing' && trend.rSquared > 0.2) {
      insights.add(
          '📉 いい調子サイ！使用時間がだんだん減ってきてるサイ！この調子で続けるサイ');
    } else if (trend.trendDirection == 'increasing' && trend.rSquared > 0.2) {
      insights.add(
          '📈 最近ちょっとSNSの時間が増えてきてるサイ…意識して減らしてみるサイ');
    } else {
      insights.add(
          '➡️ 使用時間は安定してるサイ。もう少し減らせるとベストサイ！');
    }

    // 平均 vs 制限 → アドバイス付き
    if (stats.mean > timeLimit * 1.5) {
      insights.add(
          '🚨 1日の目標${timeLimit}分に対して、平均${stats.mean.round()}分も使ってるサイ！'
          'まずは${(stats.mean * 0.8).round()}分を目指してみるサイ');
    } else if (stats.mean > timeLimit) {
      insights.add(
          '⚠️ 目標${timeLimit}分を少しオーバーしてるサイ（平均${stats.mean.round()}分）。'
          'あと${(stats.mean - timeLimit).round()}分減らすだけサイ！');
    } else {
      insights.add(
          '✅ 目標${timeLimit}分以内に収まってるサイ！（平均${stats.mean.round()}分）すばらしいサイ！');
    }

    // 曜日パターン → 具体的なアドバイス
    final dayNames = {
      1: '月', 2: '火', 3: '水', 4: '木', 5: '金', 6: '土', 7: '日'
    };
    final peakDayName = dayNames[dayPattern.peakDay];
    insights.add(
        '📅 ${peakDayName}曜日が一番SNSを見がちサイ（平均${dayPattern.averageByDay[dayPattern.peakDay]?.round()}分）。'
        '${peakDayName}曜日は特に意識してみるサイ！');

    if (dayPattern.weekendEffect > 20) {
      insights.add(
          '🏖️ 休日は平日の${(dayPattern.weekendEffect / 100 + 1).toStringAsFixed(1)}倍もSNSを見てるサイ。'
          '休日こそ外に出かけるサイ！');
    }

    // 時間帯 → 具体的な対策
    String timeAdvice;
    if (hourly.peakHour >= 22 || hourly.peakHour < 5) {
      timeAdvice = '寝る前のスマホは睡眠に悪影響サイ！寝室にスマホを持ち込まないのがおすすめサイ';
    } else if (hourly.peakHour >= 18) {
      timeAdvice = '夜の時間を趣味や運動に使ってみるサイ！';
    } else if (hourly.peakHour >= 12) {
      timeAdvice = 'お昼休みの使いすぎに注意サイ！';
    } else {
      timeAdvice = '朝の時間は1日の準備に使うサイ！';
    }
    insights.add(
        '🕐 ${hourly.peakHour}時台が一番使っている時間帯サイ。$timeAdvice');

    // セッションパターン → やさしい表現
    if (session.usagePattern == 'binge') {
      insights.add(
          '📱 1回開くと平均${session.avgSessionDurationMinutes.round()}分使い続けてるサイ。'
          '「5分だけ」とタイマーをセットしてから開くクセをつけるサイ！');
    } else if (session.usagePattern == 'frequent') {
      insights.add(
          '📱 1日に平均${session.avgSessionsPerDay.round()}回も開いてるサイ！'
          '通知をオフにすると、つい開いちゃう回数が減るサイ');
    } else {
      insights.add(
          '📱 使い方のバランスが良いサイ！'
          '1日${session.avgSessionsPerDay.round()}回、1回${session.avgSessionDurationMinutes.round()}分は理想的サイ');
    }

    // 異常値 → わかりやすく
    if (anomalies.anomalies.isNotEmpty) {
      final highAnomalies =
          anomalies.anomalies.where((a) => a.type == 'high').length;
      if (highAnomalies > 0) {
        insights.add(
            '⚡ 過去${stats.count}日間で${highAnomalies}日だけ極端に使いすぎた日があったサイ。'
            'どんな日だったか振り返ってみるサイ');
      }
    }

    // 明日の予測
    insights.add(
        '🔮 明日の予測: 約${trend.predictedTomorrow.round()}分使いそうサイ。'
        '意識して$timeLimit分以内を目指すサイ！');

    return insights;
  }

  // ========== 空レポート ==========
  static AnalyticsReport _emptyReport() {
    return AnalyticsReport(
      overallStats: _emptyStats(),
      trend: const TrendAnalysis(
        slope: 0,
        intercept: 0,
        rSquared: 0,
        trendDirection: 'stable',
        predictedTomorrow: 0,
        movingAverage: [],
      ),
      dayOfWeekPattern: const DayOfWeekPattern(
        averageByDay: {},
        peakDay: 1,
        lowDay: 1,
        weekdayAverage: 0,
        weekendAverage: 0,
        weekendEffect: 0,
      ),
      hourlyPattern: const HourlyPattern(
        averageByHour: {},
        peakHour: 0,
        lowHour: 0,
        morningTotal: 0,
        afternoonTotal: 0,
        eveningTotal: 0,
        nightTotal: 0,
      ),
      anomalies: const AnomalyDetection(
        anomalies: [],
        upperBound: 0,
        lowerBound: 0,
      ),
      sessionAnalysis: SessionAnalysis(
        sessionDurationStats: _emptyStats(),
        sessionCountStats: _emptyStats(),
        avgSessionsPerDay: 0,
        avgSessionDurationMinutes: 0,
        usagePattern: 'balanced',
      ),
      correlations: const [],
      perAppStats: const {},
      healthScore: 100,
      insights: const ['データがまだないサイ🦏'],
    );
  }

  static DescriptiveStats _emptyStats() {
    return const DescriptiveStats(
      mean: 0,
      median: 0,
      standardDeviation: 0,
      variance: 0,
      min: 0,
      max: 0,
      q1: 0,
      q3: 0,
      iqr: 0,
      skewness: 0,
      count: 0,
    );
  }
}
