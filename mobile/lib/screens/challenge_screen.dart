import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../models/app_usage.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  @override
  Widget build(BuildContext context) {
    final challenges = ref.watch(challengeProvider);
    final streak = ref.read(challengeProvider.notifier).streakDays;
    final totalUsage = ref.watch(totalUsageProvider);

    // 今日のチャレンジ
    final today = DateTime.now();
    final todayChallenges = challenges.where((c) =>
        c.date.year == today.year &&
        c.date.month == today.month &&
        c.date.day == today.day);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 連続達成
          Center(
            child: RhinoCharacter(
              size: 80,
              message: streak > 0
                  ? '$streak日連続達成サイ！🔥'
                  : '今日からチャレンジ開始サイ！🦏',
            ),
          ),

          const SizedBox(height: 16),

          // 連続達成カード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Text(
                        '$streak日',
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                      ),
                      Text(
                        '連続達成',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const Text('🔥', style: TextStyle(fontSize: 32)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 新しいチャレンジ作成
          Text(
            '🎯 新しいチャレンジ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          _buildQuickChallenge(context, 'SNS 30分以内', 30),
          _buildQuickChallenge(context, 'SNS 1時間以内', 60),
          _buildQuickChallenge(context, 'SNS 2時間以内', 120),
          _buildCustomChallengeButton(context),

          const SizedBox(height: 24),

          // 今日のチャレンジ
          Text(
            '📋 今日のチャレンジ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          if (todayChallenges.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Text('🦏', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(
                        'まだチャレンジがないサイ\n上のボタンからチャレンジを始めるサイ！',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...todayChallenges.map((challenge) => _buildChallengeCard(
                  context,
                  challenge,
                  totalUsage,
                )),

          const SizedBox(height: 24),

          // 過去の記録
          Text(
            '📅 過去のチャレンジ記録',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          ...challenges
              .where((c) => !(c.date.year == today.year &&
                  c.date.month == today.month &&
                  c.date.day == today.day))
              .toList()
              .reversed
              .take(10)
              .map((c) => Card(
                    child: ListTile(
                      leading: Icon(
                        c.isAchieved ? Icons.check_circle : Icons.cancel,
                        color: c.isAchieved ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      title: Text(c.title),
                      subtitle: Text(
                        '${c.date.month}/${c.date.day} - 目標: ${c.targetTime.inMinutes}分',
                      ),
                      trailing: Text(
                        c.isAchieved ? '達成🎉' : '未達成😢',
                        style: TextStyle(
                          color: c.isAchieved ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuickChallenge(
      BuildContext context, String title, int targetMinutes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Text('🎯', style: TextStyle(fontSize: 24)),
        title: Text(title),
        subtitle: Text('目標: ${targetMinutes}分以内'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
          onPressed: () => _addChallenge(title, targetMinutes),
          child:
              const Text('挑戦！', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildCustomChallengeButton(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Text('✏️', style: TextStyle(fontSize: 24)),
        title: const Text('カスタムチャレンジ'),
        subtitle: const Text('自分で目標を設定'),
        trailing: ElevatedButton(
          onPressed: () => _showCustomChallengeDialog(context),
          child: const Text('作成'),
        ),
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    Challenge challenge,
    Duration totalUsage,
  ) {
    final isWithinTarget =
        totalUsage.inMinutes <= challenge.targetTime.inMinutes;
    final progress = challenge.targetTime.inMinutes > 0
        ? (totalUsage.inMinutes / challenge.targetTime.inMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  challenge.isAchieved ? '✅' : (isWithinTarget ? '🎯' : '⚠️'),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '現在: ${totalUsage.inMinutes}分 / 目標: ${challenge.targetTime.inMinutes}分',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!challenge.isAchieved)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isWithinTarget ? Colors.green : Colors.grey,
                    ),
                    onPressed: isWithinTarget
                        ? () {
                            ref
                                .read(challengeProvider.notifier)
                                .updateChallenge(challenge.id, true);
                          }
                        : null,
                    child: const Text('達成！',
                        style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(
                  isWithinTarget ? Colors.green : Colors.red,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addChallenge(String title, int targetMinutes) {
    final challenge = Challenge(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      targetTime: Duration(minutes: targetMinutes),
      date: DateTime.now(),
      isAchieved: false,
    );
    ref.read(challengeProvider.notifier).addChallenge(challenge);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('チャレンジ「$title」を開始しました🦏🎯')),
    );
  }

  void _showCustomChallengeDialog(BuildContext context) {
    final titleController = TextEditingController();
    int targetMinutes = 60;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('🎯 カスタムチャレンジ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'チャレンジ名',
                  hintText: '例: Instagram 30分以内',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('目標時間: $targetMinutes分'),
              Slider(
                value: targetMinutes.toDouble(),
                min: 10,
                max: 180,
                divisions: 17,
                label: '$targetMinutes分',
                activeColor: primaryColor,
                onChanged: (v) {
                  setDialogState(() => targetMinutes = v.round());
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  _addChallenge(title, targetMinutes);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('作成', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
