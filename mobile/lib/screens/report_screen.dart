import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../models/app_usage.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageData = ref.watch(usageDataProvider);
    final overLimitCount = ref.watch(overLimitCountProvider);
    final timeLimit = ref.watch(timeLimitProvider);
    final totalUsage = ref.watch(totalUsageProvider);

    final totalMinutes = totalUsage.inMinutes;
    final savedMinutes = (timeLimit * 2 - totalMinutes).clamp(0, timeLimit * 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // サイのコメント
          Center(
            child: RhinoCharacter(
              size: 80,
              message: _getReportComment(totalMinutes, timeLimit),
            ),
          ),

          const SizedBox(height: 24),

          // サマリーカード
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: '合計使用時間',
                  value: _formatDuration(totalUsage),
                  icon: Icons.access_time,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  title: '制限超過',
                  value: '$overLimitCount回',
                  icon: Icons.warning,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  title: '節約時間',
                  value: '$savedMinutes分',
                  icon: Icons.savings,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 円グラフ
          Text(
            '📊 アプリ別使用割合',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: usageData.isEmpty
                ? const Center(child: Text('データがありません'))
                : _buildPieChart(context, usageData),
          ),

          const SizedBox(height: 24),

          // 棒グラフ
          Text(
            '📈 アプリ別使用時間',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: usageData.isEmpty
                ? const Center(child: Text('データがありません'))
                : _buildBarChart(context, usageData, timeLimit),
          ),

          const SizedBox(height: 24),

          // 詳細リスト
          Text(
            '📋 詳細',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...usageData.map((usage) {
            final app = targetApps.firstWhere(
              (a) => a.packageName == usage.packageName,
              orElse: () => targetApps.first,
            );
            final isOver = usage.usageTime.inMinutes > timeLimit ~/ 3;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: app.color.withValues(alpha: 0.2),
                  child: Icon(app.icon, color: app.color),
                ),
                title: Text(usage.appName),
                subtitle: Text(_formatDuration(usage.usageTime)),
                trailing: isOver
                    ? const Icon(Icons.warning, color: Colors.orange)
                    : const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          }),

          const SizedBox(height: 24),

          // 効率化スコア
          _buildEfficiencyCard(context, totalMinutes, timeLimit),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, List<AppUsageData> usageData) {
    final totalMinutes =
        usageData.fold<int>(0, (sum, u) => sum + u.usageTime.inMinutes);
    if (totalMinutes == 0) {
      return const Center(child: Text('使用時間がありません'));
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: usageData.asMap().entries.map((entry) {
                final usage = entry.value;
                final app = targetApps.firstWhere(
                  (a) => a.packageName == usage.packageName,
                  orElse: () => targetApps.first,
                );
                final percentage =
                    (usage.usageTime.inMinutes / totalMinutes * 100);

                return PieChartSectionData(
                  color: app.color,
                  value: usage.usageTime.inMinutes.toDouble(),
                  title: '${percentage.round()}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  radius: 80,
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 0,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: usageData.map((usage) {
              final app = targetApps.firstWhere(
                (a) => a.packageName == usage.packageName,
                orElse: () => targetApps.first,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: app.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        usage.appName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(
      BuildContext context, List<AppUsageData> usageData, int timeLimit) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (timeLimit * 1.5).toDouble(),
          barGroups: usageData.asMap().entries.map((entry) {
            final idx = entry.key;
            final usage = entry.value;
            final app = targetApps.firstWhere(
              (a) => a.packageName == usage.packageName,
              orElse: () => targetApps.first,
            );

            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: usage.usageTime.inMinutes.toDouble(),
                  color: app.color,
                  width: 32,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < usageData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        usageData[idx].appName.split(' ').first,
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}m',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 15,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: timeLimit.toDouble(),
                color: Colors.red.withValues(alpha: 0.5),
                strokeWidth: 2,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (_) => '制限: $timeLimit分',
                  style: TextStyle(
                    color: Colors.red.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEfficiencyCard(
      BuildContext context, int totalMinutes, int timeLimit) {
    // 想定最大使用時間を制限の3倍と仮定
    final maxExpected = timeLimit * 3;
    final efficiency =
        ((maxExpected - totalMinutes) / maxExpected * 100).clamp(0, 100);

    Color scoreColor;
    String scoreEmoji;
    if (efficiency >= 80) {
      scoreColor = Colors.green;
      scoreEmoji = '🌟';
    } else if (efficiency >= 50) {
      scoreColor = Colors.orange;
      scoreEmoji = '💪';
    } else {
      scoreColor = Colors.red;
      scoreEmoji = '😅';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '$scoreEmoji 効率化スコア',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '${efficiency.round()}点',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: efficiency / 100,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(scoreColor),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              efficiency >= 80
                  ? 'すばらしいサイ！集中力がバツグンサイ！🦏✨'
                  : efficiency >= 50
                      ? 'まあまあサイ。もう少しがんばるサイ！🦏'
                      : 'SNS見すぎサイ…明日はがんばるサイ！🦏💦',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getReportComment(int totalMinutes, int timeLimit) {
    if (totalMinutes == 0) return 'まだデータがないサイ🦏';
    if (totalMinutes < timeLimit * 0.5) return '今日は優秀サイ！🦏✨';
    if (totalMinutes < timeLimit) return 'もう少しで制限サイ…🦏';
    return '制限超えてるサイ！反省するサイ！🦏💢';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) return '$hours時間$minutes分';
    return '$minutes分';
  }
}
