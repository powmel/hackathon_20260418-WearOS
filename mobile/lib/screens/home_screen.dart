import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../constants/rhino_assets.dart';
import '../models/app_usage.dart';
import '../providers/app_providers.dart';
import '../services/usage_stats_service.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import '../widgets/common_widgets.dart';

// ── デバッグ用: 0=実データ, 1=good, 2=warning, 3=over ──
final _debugStateProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _refreshTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsageData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadUsageData(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsageData() async {
    final usages = await UsageStatsService.getTodayUsage();
    if (!mounted) return;

    ref.read(usageDataProvider.notifier).updateUsage(usages);

    final timeLimit = ref.read(timeLimitProvider);
    final totalMinutes =
        usages.fold<int>(0, (sum, u) => sum + u.usageTime.inMinutes);

    if (totalMinutes > timeLimit) {
      final mode = ref.read(rhinoModeProvider);
      final soundEnabled = ref.read(soundEnabledProvider);
      await NotificationService.showRhinoNotification(mode: mode);
      if (soundEnabled) {
        await SoundService.playRhinoSound();
      }
      ref.read(overLimitCountProvider.notifier).increment();
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final usageData = ref.watch(usageDataProvider);
    final timeLimit = ref.watch(timeLimitProvider);
    final totalUsage = ref.watch(totalUsageProvider);
    final debugState = ref.watch(_debugStateProvider);

    final int totalMinutes = switch (debugState) {
      1 => (timeLimit * 0.3).round(),
      2 => (timeLimit * 0.8).round(),
      3 => (timeLimit * 1.3).round(),
      _ => totalUsage.inMinutes,
    };

    final isOverLimit = totalMinutes > timeLimit;
    final UsageStatus status = isOverLimit
        ? UsageStatus.over
        : totalMinutes > timeLimit * 0.7
            ? UsageStatus.warning
            : UsageStatus.good;

    final pace = calcIdealPace(totalMinutes, timeLimit);

    return RefreshIndicator(
      onRefresh: _loadUsageData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 挨拶
            _GreetingHeader(),
            const SizedBox(height: 12),

            // デバッグバナー
            if (debugState != 0) _buildDebugBanner(context),

            // ━━ セクション1: 使用状況 ━━
            _UsageStatusCard(
              totalMinutes: totalMinutes,
              timeLimit: timeLimit,
              status: status,
              pace: pace,
            ),

            const SizedBox(height: 16),

            // ━━ セクション2: サイの状態 ━━
            _RhinoStatusCard(
              status: status,
              onLongPress: _cycleDebugState,
            ),

            const SizedBox(height: 24),

            // ━━ セクション3: アプリ別使用時間 ━━
            _SectionHeader(title: 'アプリ別使用時間'),
            const SizedBox(height: 10),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...targetApps.map((app) {
                final usage = usageData.firstWhere(
                  (u) => u.packageName == app.packageName,
                  orElse: () => AppUsageData(
                    packageName: app.packageName,
                    appName: app.name,
                    usageTime: Duration.zero,
                    date: DateTime.now(),
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: UsageBar(
                    appName: app.name,
                    icon: app.icon,
                    color: app.color,
                    usageTime: usage.usageTime,
                    limitTime: Duration(minutes: timeLimit),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _cycleDebugState() {
    final cur = ref.read(_debugStateProvider);
    ref.read(_debugStateProvider.notifier).state = (cur + 1) % 4;
  }

  Widget _buildDebugBanner(BuildContext context) {
    final debugState = ref.watch(_debugStateProvider);
    final labels = ['', 'Good', 'Warning', 'Over'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.bug_report_outlined,
                size: 14, color: Colors.deepPurple.shade300),
            const SizedBox(width: 6),
            Text(
              'Preview: ${labels[debugState]}',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.deepPurple.shade400,
                  fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => ref.read(_debugStateProvider.notifier).state = 0,
              child: Icon(Icons.close,
                  size: 14, color: Colors.deepPurple.shade300),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// 挨拶ヘッダー
// ================================================================
class _GreetingHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final userGoal = ref.watch(userGoalProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'おはようございます' : hour < 18 ? 'こんにちは' : 'こんばんは';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName.isNotEmpty ? '$greeting、${userName}さん' : greeting,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (userGoal.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.flag, size: 14, color: isDark ? accentColor : primaryColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    userGoal,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================
// セクションヘッダー
// ================================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ================================================================
// セクション1: 使用状況カード（リング左 + テキスト情報右）
// ================================================================
class _UsageStatusCard extends StatelessWidget {
  final int totalMinutes;
  final int timeLimit;
  final UsageStatus status;
  final PaceInfo pace;

  const _UsageStatusCard({
    required this.totalMinutes,
    required this.timeLimit,
    required this.status,
    required this.pace,
  });

  @override
  Widget build(BuildContext context) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final timeText = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    final remaining = timeLimit - totalMinutes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── 左: ダブルリング ──
          _DoubleRing(
            totalMinutes: totalMinutes,
            timeLimit: timeLimit,
            status: status,
            pace: pace,
          ),
          const SizedBox(width: 20),
          // ── 右: テキスト情報ブロック ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 使用時間（大きく）
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: status.subtleColor,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '/ $timeLimit分が目標',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 14),
                // ステータスバッジ
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 14, color: status.subtleColor),
                      const SizedBox(width: 5),
                      Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: status.subtleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // 残り時間 or 超過情報
                Text(
                  remaining >= 0
                      ? '残り $remaining分'
                      : '${-remaining}分オーバー',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: remaining >= 0
                        ? Colors.grey.shade600
                        : const Color(0xFFC62828),
                  ),
                ),
                const SizedBox(height: 4),
                // アドバイス1行
                Text(
                  pace.advice,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// セクション2: サイの状態カード（左テキスト + 右キャラ）
// ================================================================
class _RhinoStatusCard extends StatelessWidget {
  final UsageStatus status;
  final VoidCallback onLongPress;

  const _RhinoStatusCard({
    required this.status,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクションタイトル
          Row(
            children: [
              Icon(Icons.pets_rounded,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'サイの様子',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // コンテンツ: 吹き出し（左）+ キャラ（右）
          Row(
            children: [
              // ── 左: 吹き出し風コメント ──
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    status.rhinoComment,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: status.subtleColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ── 右: キャラクター画像 ──
              GestureDetector(
                onLongPress: onLongPress,
                child: RhinoCharacter(
                  size: 88,
                  imagePath: RhinoAssets.fromStatus(status.toRhinoStatus),
                  isAngry: status == UsageStatus.over,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ダブルリング（中央にはステータスのみ、テキスト情報は外に移動）
// ================================================================
class _DoubleRing extends StatelessWidget {
  final int totalMinutes;
  final int timeLimit;
  final UsageStatus status;
  final PaceInfo pace;

  const _DoubleRing({
    required this.totalMinutes,
    required this.timeLimit,
    required this.status,
    required this.pace,
  });

  static const double _size = 140;
  static const double _stroke = 12.0;
  static const double _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    final usageRatio = timeLimit > 0
        ? (totalMinutes / timeLimit).clamp(0.0, 1.0)
        : 0.0;
    final paceRatio = pace.idealRatio.clamp(0.0, 1.0);

    final outerColor = status.color;
    final innerColor = Colors.grey.shade400;

    final percent = timeLimit > 0
        ? (totalMinutes / timeLimit * 100).round()
        : 0;

    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _DoubleRingPainter(
          outerProgress: usageRatio,
          innerProgress: paceRatio,
          outerColor: outerColor,
          innerColor: innerColor,
          strokeWidth: _stroke,
          gap: _gap,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: status.subtleColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '使用率',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// UsageStatus enum
// ================================================================
enum UsageStatus {
  good,
  warning,
  over;

  Color get color => switch (this) {
        good => const Color(0xFF4CAF50),
        warning => const Color(0xFFFFA726),
        over => const Color(0xFFEF5350),
      };

  Color get subtleColor => switch (this) {
        good => const Color(0xFF2E7D32),
        warning => const Color(0xFFE65100),
        over => const Color(0xFFC62828),
      };

  String get label => switch (this) {
        good => '良いペース',
        warning => '使いすぎ注意',
        over => '制限オーバー',
      };

  IconData get icon => switch (this) {
        good => Icons.check_circle_outline_rounded,
        warning => Icons.info_outline_rounded,
        over => Icons.error_outline_rounded,
      };

  String get rhinoComment => switch (this) {
        good => 'いい調子サイ！\nこのまま続けるサイ',
        warning => 'そろそろ注意サイ…\n少し休憩しなサイ',
        over => '使いすぎサイ！\nスマホを置くサイ',
      };

  RhinoStatus get toRhinoStatus => switch (this) {
        good => RhinoStatus.good,
        warning => RhinoStatus.normal,
        over => RhinoStatus.bad,
      };
}

// ================================================================
// PaceInfo
// ================================================================
class PaceInfo {
  final double idealMinutes;
  final double idealRatio;
  final double paceRatio;
  final bool isOverPace;
  final String advice;

  const PaceInfo({
    required this.idealMinutes,
    required this.idealRatio,
    required this.paceRatio,
    required this.isOverPace,
    required this.advice,
  });
}

PaceInfo calcIdealPace(int totalMinutes, int timeLimit) {
  final now = DateTime.now();
  const wakeHour = 7;
  const activeHours = 17;

  final elapsed =
      (now.hour + now.minute / 60.0 - wakeHour).clamp(0.0, activeHours.toDouble());
  final dayProgress = elapsed / activeHours;

  final idealMinutes = timeLimit * dayProgress;
  final idealRatio = dayProgress;
  final paceRatio = idealMinutes > 0 ? totalMinutes / idealMinutes : 0.0;
  final isOverPace = paceRatio > 1.05;

  final remaining = timeLimit - totalMinutes;
  final diff = (totalMinutes - idealMinutes).round();

  final String advice;
  if (totalMinutes > timeLimit) {
    advice = '${-remaining}分超過 — 少し離れてみましょう';
  } else if (diff > 15) {
    advice = '理想より$diff分多め — ペースダウンを';
  } else if (diff > 0) {
    advice = 'もう少し意識してみましょう';
  } else if (diff > -10) {
    advice = 'いいペースをキープ中';
  } else {
    advice = '余裕のある使い方ができています';
  }

  return PaceInfo(
    idealMinutes: idealMinutes,
    idealRatio: idealRatio,
    paceRatio: paceRatio,
    isOverPace: isOverPace,
    advice: advice,
  );
}

// ================================================================
// ダブルリング CustomPainter
// ================================================================
class _DoubleRingPainter extends CustomPainter {
  final double outerProgress;
  final double innerProgress;
  final Color outerColor;
  final Color innerColor;
  final double strokeWidth;
  final double gap;

  _DoubleRingPainter({
    required this.outerProgress,
    required this.innerProgress,
    required this.outerColor,
    required this.innerColor,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (min(size.width, size.height) - strokeWidth) / 2;
    final innerRadius = outerRadius - strokeWidth - gap;

    // ── 外側: 背景トラック ──
    _drawTrack(canvas, center, outerRadius, outerColor.withValues(alpha: 0.12));
    // ── 外側: 使用率 ──
    _drawArc(canvas, center, outerRadius, outerProgress, outerColor);

    // ── 内側: 背景トラック ──
    _drawTrack(canvas, center, innerRadius, innerColor.withValues(alpha: 0.10));
    // ── 内側: 理想ペース（ガイドライン風にやや透明） ──
    _drawArc(
        canvas, center, innerRadius, innerProgress, innerColor.withValues(alpha: 0.35));
  }

  void _drawTrack(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawArc(Canvas canvas, Offset center, double radius, double progress,
      Color color) {
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DoubleRingPainter old) =>
      old.outerProgress != outerProgress ||
      old.innerProgress != innerProgress ||
      old.outerColor != outerColor;
}
