import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../constants/app_constants.dart';
import '../providers/app_providers.dart';
import '../services/notification_service.dart';
import '../services/usage_stats_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rhinoMode = ref.watch(rhinoModeProvider);
    final timeLimit = ref.watch(timeLimitProvider);
    final notifInterval = ref.watch(notificationIntervalProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
    final darkMode = ref.watch(darkModeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // プロフィールセクション
          _SectionTitle(title: '👤 プロフィール'),
          _ProfileCard(),
          const SizedBox(height: 24),

          // 権限設定セクション
          _SectionTitle(title: '⚙️ 権限設定'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('使用統計アクセス権限'),
              subtitle: const Text('SNS使用時間の取得に必要です'),
              trailing: ElevatedButton(
                onPressed: () => _requestUsagePermission(context),
                child: const Text('設定'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('通知権限'),
              subtitle: const Text('警告通知の送信に必要です'),
              trailing: ElevatedButton(
                onPressed: () => _requestNotifPermission(context),
                child: const Text('設定'),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // バックグラウンド監視
          _SectionTitle(title: '👁️ リアルタイム監視'),
          _MonitoringCard(timeLimit: timeLimit),

          const SizedBox(height: 24),

          // 制限時間設定
          _SectionTitle(title: '⏰ 制限時間'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1日のSNS合計制限: $timeLimit分',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Slider(
                    value: timeLimit.toDouble(),
                    min: 10,
                    max: 180,
                    divisions: 17,
                    label: '$timeLimit分',
                    activeColor: primaryColor,
                    onChanged: (v) {
                      ref
                          .read(timeLimitProvider.notifier)
                          .setLimit(v.round());
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('10分', style: Theme.of(context).textTheme.bodySmall),
                      Text('180分',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 通知間隔設定
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '再通知間隔: $notifInterval分ごと',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Slider(
                    value: notifInterval.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '$notifInterval分',
                    activeColor: primaryColor,
                    onChanged: (v) {
                      ref
                          .read(notificationIntervalProvider.notifier)
                          .setInterval(v.round());
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1分', style: Theme.of(context).textTheme.bodySmall),
                      Text('30分',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // サイの性格モード
          _SectionTitle(title: '🦏 サイの性格モード'),
          ...RhinoMode.values.map((mode) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<RhinoMode>(
                  value: mode,
                  groupValue: rhinoMode,
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(rhinoModeProvider.notifier).setMode(v);
                    }
                  },
                  title: Text(mode.label),
                  subtitle: Text(mode.description),
                  activeColor: primaryColor,
                ),
              )),

          const SizedBox(height: 8),

          // テスト通知
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                NotificationService.showRhinoNotification(
                  mode: rhinoMode,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('テスト通知を送信しました🦏')),
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('テスト通知を送信'),
            ),
          ),

          const SizedBox(height: 24),

          // サウンド設定
          _SectionTitle(title: '🔊 サウンド設定'),
          Card(
            child: SwitchListTile(
              title: const Text('サイの鳴き声'),
              subtitle: const Text('通知時にサイの鳴き声を再生'),
              value: soundEnabled,
              activeColor: primaryColor,
              onChanged: (_) {
                ref.read(soundEnabledProvider.notifier).toggle();
              },
            ),
          ),

          const SizedBox(height: 24),

          // テーマ設定
          _SectionTitle(title: '🎨 テーマ設定'),
          Card(
            child: SwitchListTile(
              title: const Text('ダークモード'),
              subtitle: const Text('暗い背景に切り替えます'),
              value: darkMode,
              activeColor: primaryColor,
              onChanged: (_) {
                ref.read(darkModeProvider.notifier).toggle();
              },
            ),
          ),

          const SizedBox(height: 32),

          // ログアウト
          _SectionTitle(title: '🚪 アカウント'),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'ログアウト',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('ログアウト'),
          ],
        ),
        content: const Text('本当にログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      await Amplify.Auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _requestUsagePermission(BuildContext context) async {
    final hasPermission = await UsageStatsService.hasPermission();
    if (!context.mounted) return;

    if (hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 使用統計アクセス権限は付与済みです')),
      );
    } else {
      await UsageStatsService.requestPermission();
    }
  }

  Future<void> _requestNotifPermission(BuildContext context) async {
    final granted = await NotificationService.requestPermission();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(granted ? '✅ 通知権限が付与されました' : '❌ 通知権限が拒否されました'),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _MonitoringCard extends StatefulWidget {
  final int timeLimit;

  const _MonitoringCard({required this.timeLimit});

  @override
  State<_MonitoringCard> createState() => _MonitoringCardState();
}

class _MonitoringCardState extends State<_MonitoringCard> {
  bool _isMonitoring = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkMonitoringStatus();
  }

  Future<void> _checkMonitoringStatus() async {
    final isMonitoring = await MonitorService.isMonitoring();
    if (mounted) {
      setState(() {
        _isMonitoring = isMonitoring;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMonitoring() async {
    setState(() => _isLoading = true);

    bool success;
    if (_isMonitoring) {
      success = await MonitorService.stopMonitoring();
    } else {
      // 権限チェック
      final hasPermission = await UsageStatsService.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ 使用統計アクセス権限が必要です')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      success = await MonitorService.startMonitoring(
        timeLimitMinutes: widget.timeLimit,
      );
    }

    if (success && mounted) {
      setState(() {
        _isMonitoring = !_isMonitoring;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isMonitoring ? '🦏 監視を開始しました' : '監視を停止しました'),
        ),
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isMonitoring ? Icons.visibility : Icons.visibility_off,
                  color: _isMonitoring ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'バックグラウンド監視',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        _isMonitoring
                            ? 'SNS使用中に制限超過で通知します'
                            : 'アプリを閉じても監視を続けます',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch(
                        value: _isMonitoring,
                        activeColor: primaryColor,
                        onChanged: (_) => _toggleMonitoring(),
                      ),
              ],
            ),
            if (_isMonitoring) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '制限${widget.timeLimit}分で監視中',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final userGoal = ref.watch(userGoalProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: primaryColor,
                radius: 24,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              title: Text(
                userName.isNotEmpty ? userName : '未設定',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Text(
                userGoal.isNotEmpty ? userGoal : '目標未設定',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.black54,
                  fontSize: 13,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit_outlined, color: primaryColor),
                onPressed: () => _showEditProfileDialog(context, ref, userName, userGoal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    String currentGoal,
  ) {
    final nameController = TextEditingController(text: currentName);
    final goalController = TextEditingController(text: currentGoal);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('プロフィール編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ユーザー名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: goalController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '目標',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref.read(userNameProvider.notifier).setName(nameController.text.trim());
              }
              ref.read(userGoalProvider.notifier).setGoal(goalController.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
