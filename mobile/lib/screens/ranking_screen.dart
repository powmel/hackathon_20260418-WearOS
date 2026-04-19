import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../constants/rhino_assets.dart';
import '../models/app_usage.dart';
import '../providers/app_providers.dart';
import '../services/wear_sync_service.dart';
import '../widgets/common_widgets.dart';

const _maxVisibleRows = 10;

class _RankingTab {
  final String label;
  final IconData icon;
  final String subtitle;
  final String sortKey;
  final List<UserRankingData> Function(List<UserRankingData>) sorter;
  final String Function(UserRankingData) valueBuilder;
  final Color Function(UserRankingData) colorBuilder;
  final String unit;

  const _RankingTab({
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.sortKey,
    required this.sorter,
    required this.valueBuilder,
    required this.colorBuilder,
    this.unit = '',
  });
}

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _wearSync = WearSyncService();

  late final List<_RankingTab> _tabs = [
    _RankingTab(
      label: 'スコア',
      icon: Icons.emoji_events_rounded,
      subtitle: 'スコアが高いほど SNS を上手に管理できています',
      sortKey: 'efficiencyScore',
      sorter: (list) => List.from(list)
        ..sort((a, b) => b.efficiencyScore.compareTo(a.efficiencyScore)),
      valueBuilder: (u) => u.efficiencyScore.toStringAsFixed(1),
      colorBuilder: (u) => u.efficiencyScore >= 80
          ? const Color(0xFF2E7D32)
          : u.efficiencyScore >= 50
              ? const Color(0xFFE65100)
              : const Color(0xFFC62828),
      unit: '点',
    ),
    _RankingTab(
      label: '使用時間',
      icon: Icons.timer_rounded,
      subtitle: '今週の使用時間が少ない人ほど上位です',
      sortKey: 'weeklyTotalMinutes',
      sorter: (list) => List.from(list)
        ..sort((a, b) => a.weeklyTotalMinutes.compareTo(b.weeklyTotalMinutes)),
      valueBuilder: (u) => _formatMinutes(u.weeklyTotalMinutes),
      colorBuilder: (u) => u.weeklyTotalMinutes < 150
          ? const Color(0xFF2E7D32)
          : u.weeklyTotalMinutes < 300
              ? const Color(0xFFE65100)
              : const Color(0xFFC62828),
    ),
    _RankingTab(
      label: '連続達成',
      icon: Icons.local_fire_department_rounded,
      subtitle: '目標を連続で達成した日数のランキングです',
      sortKey: 'streakDays',
      sorter: (list) => List.from(list)
        ..sort((a, b) => b.streakDays.compareTo(a.streakDays)),
      valueBuilder: (u) => '${u.streakDays}',
      colorBuilder: (u) => u.streakDays >= 7
          ? const Color(0xFF2E7D32)
          : u.streakDays >= 3
              ? const Color(0xFFE65100)
              : stoneGray,
      unit: '日',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == _selectedIndex) return;
    _animController.reset();
    setState(() => _selectedIndex = index);
    ref.read(rankingDataProvider.notifier).fetch(sortBy: _tabs[index].sortKey);
    _animController.forward();
  }

  Future<void> _onRefresh() async {
    await ref
        .read(rankingDataProvider.notifier)
        .fetch(sortBy: _tabs[_selectedIndex].sortKey);
    _syncRankingToWear();
  }

  void _syncRankingToWear() {
    final rankingAsync = ref.read(rankingDataProvider);
    rankingAsync.whenData((rankings) {
      final sorted = _tabs[0].sorter(rankings);
      final top10 = sorted.take(10).toList();
      _wearSync.sendRanking(
        top10.asMap().entries.map((e) => {
          'rank': e.key + 1,
          'displayName': e.value.displayName,
          'score': e.value.efficiencyScore,
          'isYou': e.value.userId == 'user_you',
        }).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final rankingAsync = ref.watch(rankingDataProvider);
    final tab = _tabs[_selectedIndex];

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: accentColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildTabBar(context),
            const SizedBox(height: 6),
            _buildSubtitle(context, tab),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fadeAnim,
              child: rankingAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => _buildErrorState(context),
                data: (rankings) {
                  final sorted = tab.sorter(rankings);
                  return Column(
                    children: [
                      if (sorted.length >= 3)
                        _buildPodium(context, sorted, tab),
                      const SizedBox(height: 16),
                      if (sorted.length > 3)
                        _buildRankingList(context, sorted, tab),
                      const SizedBox(height: 16),
                      _buildGlobalStats(context, rankings),
                      const SizedBox(height: 16),
                      _buildMyRankCard(context, sorted),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A3A1A), const Color(0xFF0D2818)]
              : [primaryColor.withValues(alpha: 0.08), accentColor.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.3 : 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.leaderboard_rounded, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ランキング',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'みんなと競い合うサイ！負けないサイ！',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          RhinoCharacter(
            size: 72,
            imagePath: RhinoAssets.fighter,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final i = entry.key;
          final tab = entry.value;
          final isSelected = i == _selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 20,
                      color: isSelected ? accentColor : stoneGray,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : stoneGray,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, _RankingTab tab) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tab.subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<UserRankingData> sorted, _RankingTab tab) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _podiumCard(context, sorted[1], 2, tab)),
          const SizedBox(width: 8),
          Expanded(child: _podiumCard(context, sorted[0], 1, tab)),
          const SizedBox(width: 8),
          Expanded(child: _podiumCard(context, sorted[2], 3, tab)),
        ],
      ),
    );
  }

  Widget _podiumCard(BuildContext context, UserRankingData user, int rank, _RankingTab tab) {
    final isYou = user.userId == 'user_you';
    final double avatarRadius = rank == 1 ? 32 : 24;
    final double valueFontSize = rank == 1 ? 18 : 14;
    final double barHeight = rank == 1 ? 64 : (rank == 2 ? 48 : 32);

    final Color barColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32);

    final medals = ['', '🥇', '🥈', '🥉'];
    final crownSize = rank == 1 ? 28.0 : 20.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(medals[rank], style: TextStyle(fontSize: rank == 1 ? 36 : 26)),
        const SizedBox(height: 6),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: barColor, width: rank == 1 ? 3.5 : 2.5),
                boxShadow: [
                  BoxShadow(
                    color: barColor.withValues(alpha: rank == 1 ? 0.5 : 0.2),
                    blurRadius: rank == 1 ? 16 : 8,
                    spreadRadius: rank == 1 ? 3 : 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: isYou
                    ? questColor.withValues(alpha: 0.2)
                    : secondaryColor.withValues(alpha: 0.12),
                child: Text(
                  isYou ? '🦏' : user.displayName[0],
                  style: TextStyle(fontSize: avatarRadius * 0.75),
                ),
              ),
            ),
            if (rank == 1)
              Positioned(
                top: -14,
                left: 0,
                right: 0,
                child: Center(
                  child: Text('👑', style: TextStyle(fontSize: crownSize)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: rank == 1 ? 14 : 12,
            color: isYou ? questColor : null,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          '${tab.valueBuilder(user)}${tab.unit}',
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.w800,
            color: tab.colorBuilder(user),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [barColor, barColor.withValues(alpha: 0.4)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: barColor.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: rank == 1 ? 24 : 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingList(BuildContext context, List<UserRankingData> sorted, _RankingTab tab) {
    final remaining = sorted.sublist(3);
    final youIndex = remaining.indexWhere((u) => u.userId == 'user_you');
    final showCount = _maxVisibleRows - 3;

    final List<_RankRow> rows = [];

    if (remaining.length <= showCount) {
      for (var i = 0; i < remaining.length; i++) {
        rows.add(_RankRow(rank: i + 4, user: remaining[i]));
      }
    } else {
      for (var i = 0; i < showCount; i++) {
        rows.add(_RankRow(rank: i + 4, user: remaining[i]));
      }
      if (youIndex >= showCount) {
        rows.add(const _RankRow(rank: -1, user: null));
        rows.add(_RankRow(rank: youIndex + 4, user: remaining[youIndex]));
      }
    }

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.format_list_numbered_rounded, size: 18, color: stoneGray),
                  const SizedBox(width: 8),
                  Text(
                    '4位以降',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            ...rows.asMap().entries.map((entry) {
              final row = entry.value;
              if (row.user == null) return _buildEllipsisRow();
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 200 + entry.key * 60),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _buildUserRow(context, row.rank, row.user!, tab),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEllipsisRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 4, height: 4, decoration: BoxDecoration(color: stoneGray.withValues(alpha: 0.4), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Container(width: 4, height: 4, decoration: BoxDecoration(color: stoneGray.withValues(alpha: 0.4), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Container(width: 4, height: 4, decoration: BoxDecoration(color: stoneGray.withValues(alpha: 0.4), shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRow(BuildContext context, int rank, UserRankingData user, _RankingTab tab) {
    final isYou = user.userId == 'user_you';
    final color = tab.colorBuilder(user);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isYou
            ? questColor.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isYou
            ? Border.all(color: questColor.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: rank <= 5 ? accentColor : stoneGray,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isYou ? questColor.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: isYou
                  ? questColor.withValues(alpha: 0.15)
                  : secondaryColor.withValues(alpha: 0.1),
              child: Text(
                isYou ? '🦏' : user.displayName[0],
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isYou ? '${user.displayName}（あなた）' : user.displayName,
                  style: TextStyle(
                    fontWeight: isYou ? FontWeight.w700 : FontWeight.w500,
                    color: isYou ? questColor : null,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isYou)
                  Text(
                    'がんばってるサイ！',
                    style: TextStyle(fontSize: 11, color: questColor.withValues(alpha: 0.7)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${tab.valueBuilder(user)}${tab.unit}',
              style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalStats(BuildContext context, List<UserRankingData> rankings) {
    if (rankings.isEmpty) return const SizedBox.shrink();

    final avgScore = rankings.map((r) => r.efficiencyScore).reduce((a, b) => a + b) / rankings.length;
    final avgMinutes = (rankings.map((r) => r.weeklyTotalMinutes).reduce((a, b) => a + b) / rankings.length).round();
    final avgStreak = rankings.map((r) => r.streakDays).reduce((a, b) => a + b) / rankings.length;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: magicBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_rounded, color: magicBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'みんなの平均',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${rankings.length}人参加',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _miniStatCard(context, 'スコア', avgScore.toStringAsFixed(1), Icons.star_rounded, accentColor)),
              const SizedBox(width: 10),
              Expanded(child: _miniStatCard(context, '週の使用', _formatMinutes(avgMinutes), Icons.timer_rounded, magicBlue)),
              const SizedBox(width: 10),
              Expanded(child: _miniStatCard(context, '連続達成', '${avgStreak.toStringAsFixed(1)}日', Icons.local_fire_department_rounded, Colors.deepOrange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankCard(BuildContext context, List<UserRankingData> sorted) {
    final myIndex = sorted.indexWhere((u) => u.userId == 'user_you');
    if (myIndex < 0) return const SizedBox.shrink();

    final me = sorted[myIndex];
    final rank = myIndex + 1;
    final total = sorted.length;
    final percentile = ((total - rank) / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            questColor.withValues(alpha: 0.08),
            questColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: questColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: questColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🦏', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'あなたの順位',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: questColor,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          '位',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: questColor,
                          ),
                        ),
                        Text(
                          ' / $total人中',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _percentileColor(percentile).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '上位',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                    Text(
                      '${100 - percentile}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _percentileColor(percentile),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentile / 100,
              backgroundColor: questColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(questColor.withValues(alpha: 0.6)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _myStatChip('スコア', '${me.efficiencyScore.toStringAsFixed(1)}点', accentColor),
              _myStatChip('使用時間', _formatMinutes(me.weeklyTotalMinutes), magicBlue),
              _myStatChip('連続', '${me.streakDays}日', Colors.deepOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _myStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  Color _percentileColor(int percentile) {
    if (percentile >= 80) return const Color(0xFF2E7D32);
    if (percentile >= 50) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'データを取得できませんでした',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return '$h時間$m分';
    }
    return '$minutes分';
  }
}

class _RankRow {
  final int rank;
  final UserRankingData? user;
  const _RankRow({required this.rank, required this.user});
}
