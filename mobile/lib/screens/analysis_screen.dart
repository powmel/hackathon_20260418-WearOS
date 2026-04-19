import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../constants/rhino_assets.dart';
import '../models/app_usage.dart';
import '../providers/app_providers.dart';
import '../services/analytics_service.dart';
import '../widgets/common_widgets.dart';

/// 分析データプロバイダー（デモデータ → 将来はDBから取得）
final analyticsDataProvider = Provider<List<DailyUsageSummary>>((ref) {
  // TODO: DB接続後は DynamoDB/AppSync からフェッチに差し替え
  return AnalyticsService.generateDemoData(days: 30);
});

/// 分析レポートプロバイダー
final analyticsReportProvider = Provider<AnalyticsReport>((ref) {
  final data = ref.watch(analyticsDataProvider);
  final timeLimit = ref.watch(timeLimitProvider);
  return AnalyticsService.analyze(data, timeLimit: timeLimit);
});

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(analyticsReportProvider);
    final data = ref.watch(analyticsDataProvider);
    final timeLimit = ref.watch(timeLimitProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimateOnVisible(
            builder: (anim) => _buildHealthScoreCard(context, report, anim),
          ),
          const SizedBox(height: 20),
          _buildAdviceCard(context, report),
          const SizedBox(height: 20),
          _buildSimpleSummary(context, report, timeLimit),
          const SizedBox(height: 20),
          _AnimateOnVisible(
            builder: (anim) =>
                _buildTrendChart(context, data, report, timeLimit, anim),
          ),
          const SizedBox(height: 20),
          _AnimateOnVisible(
            builder: (anim) => _buildDayOfWeekChart(context, report, anim),
          ),
          const SizedBox(height: 20),
          _AnimateOnVisible(
            builder: (anim) => _buildHourlyHeatmap(context, report, anim),
          ),
          const SizedBox(height: 20),
          _buildUsageTypeCard(context, report),
          const SizedBox(height: 20),
          _AnimateOnVisible(
            builder: (anim) => _buildPerAppComparison(context, report, anim),
          ),
          const SizedBox(height: 20),
          _buildAnomalyCard(context, report),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ========== ヘルススコア ==========
  Widget _buildHealthScoreCard(
      BuildContext context, AnalyticsReport report, Animation<double> animation) {
    final score = report.healthScore;
    Color scoreColor;
    String label;
    String advice;

    if (score >= 80) {
      scoreColor = Colors.green;
      label = 'とても良い';
      advice = 'すばらしいペースサイ！このまま続けるサイ';
    } else if (score >= 60) {
      scoreColor = Colors.lightGreen;
      label = 'まあまあ良い';
      advice = 'あと少し意識すれば完璧サイ';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      label = '改善の余地あり';
      advice = '1日10分減らすことから始めるサイ';
    } else {
      scoreColor = Colors.red;
      label = '要改善';
      advice = 'まずは通知オフで「つい開く」を減らすサイ';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 博士風サイの画像
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RhinoCharacter(
                  size: 72,
                  imagePath: RhinoAssets.doctor,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    advice,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scoreColor,
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'あなたのスマホ習慣スコア',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final animatedScore = score * animation.value;
                return SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: animatedScore / 100,
                          strokeWidth: 12,
                          backgroundColor:
                              Colors.grey.withValues(alpha: 0.15),
                          valueColor:
                              AlwaysStoppedAnimation(scoreColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${animatedScore.round()}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                          ),
                          Text(
                            '/ 100',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              advice,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== サイからのアドバイス ==========
  Widget _buildAdviceCard(BuildContext context, AnalyticsReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RhinoCharacter(
                  size: 44,
                  imagePath: RhinoAssets.doctor,
                ),
                const SizedBox(width: 10),
                Text(
                  'サイ博士の一言',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _doctorOneLineAdvice(report),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== シンプルサマリー（3つの数字） ==========
  Widget _buildSimpleSummary(
      BuildContext context, AnalyticsReport report, int timeLimit) {
    final stats = report.overallStats;
    final trend = report.trend;

    final withinLimitDays = stats.count > 0
        ? (stats.count *
                (stats.mean <= timeLimit
                    ? 0.7
                    : (timeLimit / stats.mean).clamp(0.1, 0.9)))
            .round()
        : 0;
    final achieveRate =
        stats.count > 0 ? (withinLimitDays / stats.count * 100).round() : 0;

    final recentAvg = trend.movingAverage.isNotEmpty
        ? trend.movingAverage.last
        : stats.mean;
    final olderAvg = trend.movingAverage.length > 7
        ? trend.movingAverage[trend.movingAverage.length - 8]
        : stats.mean;
    final changePercent =
        olderAvg > 0 ? ((recentAvg - olderAvg) / olderAvg * 100) : 0.0;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            context,
            icon: Icons.access_time_rounded,
            label: '1日の平均',
            value: '${stats.mean.round()}分',
            color: stats.mean > timeLimit ? Colors.red : secondaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            context,
            icon: Icons.emoji_events_rounded,
            label: '目標達成率',
            value: '$achieveRate%',
            color: achieveRate >= 70
                ? Colors.green
                : achieveRate >= 40
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            context,
            icon: changePercent <= 0
                ? Icons.trending_down_rounded
                : Icons.trending_up_rounded,
            label: '先週との比較',
            value:
                '${changePercent > 0 ? "+" : ""}${changePercent.round()}%',
            color: changePercent <= -5
                ? Colors.green
                : changePercent >= 5
                    ? Colors.red
                    : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ========== トレンドチャート ==========
  Widget _buildTrendChart(BuildContext context,
      List<DailyUsageSummary> data, AnalyticsReport report, int timeLimit,
      Animation<double> animation) {
    if (data.isEmpty) return const SizedBox.shrink();

    final trend = report.trend;
    final maxY = max(
      data
              .map((d) => d.totalMinutes.toDouble())
              .reduce((a, b) => a > b ? a : b) *
          1.2,
      timeLimit * 1.5,
    );

    String trendText;
    Color trendColor;
    IconData trendIcon;
    if (trend.trendDirection == 'decreasing') {
      trendText = '使用時間は減っています！';
      trendColor = Colors.green;
      trendIcon = Icons.trending_down_rounded;
    } else if (trend.trendDirection == 'increasing') {
      trendText = '使用時間が増えてきています';
      trendColor = Colors.red;
      trendIcon = Icons.trending_up_rounded;
    } else {
      trendText = '使用時間は安定しています';
      trendColor = stoneGray;
      trendIcon = Icons.trending_flat_rounded;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: secondaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.show_chart_rounded,
                      color: secondaryColor, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  '使用時間の変化',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trendText,
                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: magicBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '明日の予測: ${trend.predictedTomorrow.round()}分',
                      style: const TextStyle(
                        color: magicBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) => LineChart(
                  LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 30,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.12),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: max(1, data.length / 6).toDouble(),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          final d = data[idx].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${d.month}/${d.day}',
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 30,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}分',
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) {
                        return FlSpot(
                            e.key.toDouble(),
                            e.value.totalMinutes.toDouble() * animation.value);
                      }).toList(),
                      isCurved: false,
                      color: primaryColor.withValues(alpha: 0.4),
                      barWidth: 1,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 2,
                            color: primaryColor.withValues(alpha: 0.5),
                          );
                        },
                      ),
                    ),
                    LineChartBarData(
                      spots: trend.movingAverage.asMap().entries.map((e) {
                        return FlSpot(
                            e.key.toDouble(), e.value * animation.value);
                      }).toList(),
                      isCurved: true,
                      color: accentColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: accentColor.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: timeLimit.toDouble(),
                        color: Colors.red.withValues(alpha: 0.4),
                        strokeWidth: 2,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          labelResolver: (_) => '目標 $timeLimit分',
                          style: TextStyle(
                            color: Colors.red.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ),
                  duration: Duration.zero,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(primaryColor.withValues(alpha: 0.5), '日ごとの記録'),
                const SizedBox(width: 16),
                _legendLine(accentColor, '週間の流れ'),
                const SizedBox(width: 16),
                _legendDash(Colors.red.withValues(alpha: 0.4), '目標ライン'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _legendLine(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _legendDash(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 3,
          child: CustomPaint(painter: _DashPainter(color)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  // ========== 曜日別パターン ==========
  Widget _buildDayOfWeekChart(
      BuildContext context, AnalyticsReport report, Animation<double> animation) {
    final pattern = report.dayOfWeekPattern;
    if (pattern.averageByDay.isEmpty) return const SizedBox.shrink();

    final dayNames = ['月', '火', '水', '木', '金', '土', '日'];
    final peakDayName = dayNames[pattern.peakDay - 1];
    final maxVal = pattern.averageByDay.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: questColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: questColor, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  '曜日ごとの傾向',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: questColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '$peakDayName曜日が一番多い！',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: questColor,
                      fontSize: 15,
                    ),
                  ),
                  if (pattern.weekendEffect > 10)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '休日は平日より約${pattern.weekendEffect.round()}%多く使っています',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) => BarChart(
                  BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.2,
                  barGroups: List.generate(7, (i) {
                    final dayNum = i + 1;
                    final val = pattern.averageByDay[dayNum] ?? 0;
                    final isWeekend = dayNum >= 6;
                    final isPeak = dayNum == pattern.peakDay;

                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: val * animation.value,
                          color: isPeak
                              ? Colors.red
                              : isWeekend
                                  ? questColor
                                  : secondaryColor,
                          width: 28,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= 7) return const Text('');
                          final isPeak = idx + 1 == pattern.peakDay;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              dayNames[idx],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isPeak ? FontWeight.bold : FontWeight.normal,
                                color: isPeak
                                    ? Colors.red
                                    : idx >= 5
                                        ? questColor
                                        : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}分',
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
                  duration: Duration.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== 時間帯別ヒートマップ ==========
  Widget _buildHourlyHeatmap(
      BuildContext context, AnalyticsReport report, Animation<double> animation) {
    final hourly = report.hourlyPattern;
    if (hourly.averageByHour.isEmpty) return const SizedBox.shrink();

    final maxVal =
        hourly.averageByHour.values.reduce((a, b) => a > b ? a : b);

    String peakDesc;
    if (hourly.peakHour >= 22 || hourly.peakHour < 5) {
      peakDesc = '深夜にたくさん使っています。睡眠への影響に注意！';
    } else if (hourly.peakHour >= 18) {
      peakDesc = '夜の時間帯に集中しています';
    } else if (hourly.peakHour >= 12) {
      peakDesc = '午後の時間帯に集中しています';
    } else {
      peakDesc = '朝の時間帯に集中しています';
    }

    final timeSlots = <Map<String, dynamic>>[
      {'label': '🌅 朝 (6-11時)', 'value': hourly.morningTotal, 'color': Colors.orange},
      {'label': '☀️ 昼 (12-17時)', 'value': hourly.afternoonTotal, 'color': Colors.amber},
      {'label': '🌙 夜 (18-23時)', 'value': hourly.eveningTotal, 'color': Colors.indigo},
      {'label': '🌑 深夜 (0-5時)', 'value': hourly.nightTotal, 'color': Colors.grey},
    ];
    timeSlots.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: magicBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.schedule_rounded,
                      color: magicBlue, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  'よく使う時間帯',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: magicBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '${hourly.peakHour}時台が一番多い！',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: magicBlue,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(peakDesc,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...timeSlots.map((slot) {
              final maxSlotVal = timeSlots.first['value'] as double;
              final slotVal = slot['value'] as double;
              final ratio = maxSlotVal > 0 ? slotVal / maxSlotVal : 0.0;
              final slotColor = slot['color'] as Color;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child:
                          Text(slot['label'] as String, style: const TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: animation,
                        builder: (context, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (ratio * animation.value).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(slotColor),
                            minHeight: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${slotVal.round()}分',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: slotColor,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),
            Text('24時間の分布',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 6),
            SizedBox(
              height: 50,
              child: Row(
                children: List.generate(24, (h) {
                  final val = hourly.averageByHour[h] ?? 0;
                  final intensity = maxVal > 0 ? val / maxVal : 0.0;
                  return Expanded(
                    child: Tooltip(
                      message: '$h時台: 平均${val.toStringAsFixed(0)}分',
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            Colors.green.withValues(alpha: 0.08),
                            Colors.red.withValues(alpha: 0.85),
                            intensity,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0時', style: TextStyle(fontSize: 8, color: Colors.grey.shade500)),
                Text('6時', style: TextStyle(fontSize: 8, color: Colors.grey.shade500)),
                Text('12時', style: TextStyle(fontSize: 8, color: Colors.grey.shade500)),
                Text('18時', style: TextStyle(fontSize: 8, color: Colors.grey.shade500)),
                Text('23時', style: TextStyle(fontSize: 8, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========== 使い方タイプ ==========
  Widget _buildUsageTypeCard(BuildContext context, AnalyticsReport report) {
    final session = report.sessionAnalysis;

    String typeLabel;
    String typeDesc;
    String typeAdvice;
    Color typeColor;
    IconData typeIcon;

    switch (session.usagePattern) {
      case 'binge':
        typeLabel = 'じっくり長時間タイプ';
        typeDesc = '1回開くとつい長く見てしまう傾向があります';
        typeAdvice = '💡 アプリを開く前に「5分だけ」とタイマーをセットしてみましょう！';
        typeColor = Colors.red;
        typeIcon = Icons.hourglass_top_rounded;
        break;
      case 'frequent':
        typeLabel = 'ちょこちょこチェックタイプ';
        typeDesc = '短時間だけど何度もアプリを開く傾向があります';
        typeAdvice = '💡 通知をオフにすると、つい開いてしまう回数がグッと減ります！';
        typeColor = Colors.orange;
        typeIcon = Icons.touch_app_rounded;
        break;
      default:
        typeLabel = 'バランスタイプ';
        typeDesc = '適度な回数・時間でうまく使えています';
        typeAdvice = '💡 この良い習慣を維持しましょう！';
        typeColor = Colors.green;
        typeIcon = Icons.balance_rounded;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: secondaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_search_rounded,
                      color: secondaryColor, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  'あなたの使い方タイプ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: typeColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Icon(typeIcon, color: typeColor, size: 48),
                  const SizedBox(height: 10),
                  Text(
                    typeLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(typeDesc,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    context,
                    icon: Icons.repeat_rounded,
                    label: '1日に開く回数',
                    value: '平均 ${session.avgSessionsPerDay.round()}回',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoTile(
                    context,
                    icon: Icons.timer_rounded,
                    label: '1回あたりの時間',
                    value: '平均 ${session.avgSessionDurationMinutes.round()}分',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(typeAdvice,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: stoneGray),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  // ========== アプリ別比較 ==========
  Widget _buildPerAppComparison(
      BuildContext context, AnalyticsReport report, Animation<double> animation) {
    if (report.perAppStats.isEmpty) return const SizedBox.shrink();

    final appNames = {
      'com.instagram.android': 'Instagram',
      'com.twitter.android': 'X (Twitter)',
      'com.zhiliaoapp.musically': 'TikTok',
    };

    final sortedApps = report.perAppStats.entries.toList()
      ..sort((a, b) => b.value.mean.compareTo(a.value.mean));
    final topAppName = appNames[sortedApps.first.key] ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.apps_rounded,
                      color: accentColor, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  'アプリ別の使い方',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '一番使っているのは $topAppName！',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 12),
            ...sortedApps.map((entry) {
              final app = targetApps.firstWhere(
                (a) => a.packageName == entry.key,
                orElse: () => targetApps.first,
              );
              final stats = entry.value;
              final name = appNames[entry.key] ?? entry.key;
              final topMean = sortedApps.first.value.mean;
              final ratio = topMean > 0 ? stats.mean / topMean : 0.0;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: app.color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: app.color.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(app.icon, color: app.color, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: app.color,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '1日平均 ${stats.mean.round()}分',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: app.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (ratio * animation.value).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(app.color),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('少ない日: ${stats.min.round()}分',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        Text('多い日: ${stats.max.round()}分',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ========== 使いすぎた日 ==========
  Widget _buildAnomalyCard(BuildContext context, AnalyticsReport report) {
    final anomalies = report.anomalies;
    final highAnomalies =
        anomalies.anomalies.where((a) => a.type == 'high').toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flash_on_rounded,
                      color: Colors.amber, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  '使いすぎた日',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'いつもより極端に多く使った日を検出しました',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 12),
            if (highAnomalies.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  children: [
                    Text('🦏✨', style: TextStyle(fontSize: 32)),
                    SizedBox(height: 8),
                    Text(
                      '使いすぎた日はなかったサイ！',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ふだんの使用時間: ${anomalies.lowerBound.round()}〜${anomalies.upperBound.round()}分',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              ...highAnomalies.map((a) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.red, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${a.date.month}月${a.date.day}日',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'いつもの約${(a.value / report.overallStats.mean).toStringAsFixed(1)}倍使っていました',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${a.value.round()}分',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '💡 使いすぎた日のパターンを振り返ってみましょう。\n「何がきっかけだったか」を知ることが改善の第一歩です！',
                  style: TextStyle(height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 博士コメント: 状況に応じた1文アドバイス
  String _doctorOneLineAdvice(AnalyticsReport report) {
    final trend = report.trend;
    final stats = report.overallStats;
    final session = report.sessionAnalysis;
    final score = report.healthScore;

    if (score >= 80 && trend.trendDirection == 'decreasing') {
      return '使用時間が着実に減ってきてるサイ — この習慣を維持するサイ！';
    }
    if (score >= 80) {
      return '目標をしっかり守れてるサイ — すばらしい自己管理サイ！';
    }
    if (trend.trendDirection == 'increasing') {
      return '最近SNS時間が増加傾向サイ — 通知オフで「つい開く」を防ぐサイ';
    }
    if (session.usagePattern == 'binge') {
      return '1回の利用が長めサイ — 開く前に「5分だけ」タイマーを試すサイ';
    }
    if (session.usagePattern == 'frequent') {
      return 'こまめに開く癖があるサイ — 通知オフで開く回数を減らすサイ';
    }
    if (stats.mean > stats.median * 1.3) {
      return '使いすぎる日のムラがあるサイ — 休日の過ごし方を工夫するサイ';
    }
    return 'バランスは悪くないサイ — あと少し意識すれば理想的サイ';
  }
}

/// スクロールで表示領域に入ったときにアニメーションを開始するウィジェット
class _AnimateOnVisible extends StatefulWidget {
  final Widget Function(Animation<double> animation) builder;
  final Duration duration;

  const _AnimateOnVisible({
    required this.builder,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<_AnimateOnVisible> createState() => _AnimateOnVisibleState();
}

class _AnimateOnVisibleState extends State<_AnimateOnVisible>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _triggered = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollPosition = Scrollable.maybeOf(context)?.position;
      _scrollPosition?.addListener(_onScroll);
      _onScroll();
    });
  }

  void _onScroll() {
    if (_triggered || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final pos = box.localToGlobal(Offset.zero);
    final viewportHeight = MediaQuery.of(context).size.height;
    if (pos.dy < viewportHeight * 0.85) {
      _triggered = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_animation);
  }
}

/// 凡例用の点線ペインター
class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const dashW = 4.0;
    const gapW = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(min(x + dashW, size.width), size.height / 2),
        paint,
      );
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
