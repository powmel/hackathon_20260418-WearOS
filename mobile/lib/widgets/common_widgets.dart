import 'package:flutter/material.dart';

/// サイのキャラクター画像Widget
///
/// [imagePath] に画像アセットパスを渡す。
/// 画像が読み込めない場合はプレースホルダーアイコンを表示する。
class RhinoCharacter extends StatelessWidget {
  final double size;
  final String? message;
  final String? imagePath;
  final bool isAngry; // 後方互換のため残す

  const RhinoCharacter({
    super.key,
    this.size = 120,
    this.message,
    this.imagePath,
    this.isAngry = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isAngry
                ? Colors.red.withValues(alpha: 0.08)
                : Colors.green.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: imagePath != null
                ? Image.asset(
                    imagePath!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(size),
                  )
                : _placeholder(size),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  /// 画像が無い場合のプレースホルダー
  static Widget _placeholder(double size) {
    return Center(
      child: Icon(
        Icons.pets,
        size: size * 0.45,
        color: Colors.grey.shade400,
      ),
    );
  }
}

/// 使用時間バーWidget
class UsageBar extends StatelessWidget {
  final String appName;
  final IconData icon;
  final Color color;
  final Duration usageTime;
  final Duration limitTime;

  const UsageBar({
    super.key,
    required this.appName,
    required this.icon,
    required this.color,
    required this.usageTime,
    required this.limitTime,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = limitTime.inMinutes > 0
        ? (usageTime.inMinutes / limitTime.inMinutes).clamp(0.0, 1.5)
        : 0.0;
    final isOverLimit = usageTime >= limitTime;
    final hours = usageTime.inHours;
    final minutes = usageTime.inMinutes % 60;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  appName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                  style: TextStyle(
                    color: isOverLimit ? Colors.red : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isOverLimit) ...[
                  const SizedBox(width: 4),
                  const Text('⚠️', style: TextStyle(fontSize: 14)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(
                  isOverLimit ? Colors.red : color,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 統計カードWidget
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
