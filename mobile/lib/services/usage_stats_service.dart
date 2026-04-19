import 'package:flutter/services.dart';
import '../models/app_usage.dart';
import '../constants/app_constants.dart';

/// Android UsageStatsManager を使って使用時間を取得するサービス
class UsageStatsService {
  static const _channel = MethodChannel('com.sabori.app/usage_stats');

  /// 使用統計アクセス権限があるかチェック
  static Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 使用統計設定画面を開く
  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } on PlatformException {
      // ignore
    }
  }

  /// 今日のSNS使用時間を取得
  static Future<List<AppUsageData>> getTodayUsage() async {
    try {
      final result = await _channel.invokeMethod<Map>('getUsageStats');
      if (result == null) return _getMockData();

      final today = DateTime.now();
      final usages = <AppUsageData>[];

      for (final app in targetApps) {
        final minutes = result[app.packageName] as int? ?? 0;
        usages.add(AppUsageData(
          packageName: app.packageName,
          appName: app.name,
          usageTime: Duration(minutes: minutes),
          date: today,
        ));
      }

      return usages;
    } on PlatformException {
      return _getMockData();
    } on MissingPluginException {
      // プラットフォームチャンネル未実装（デバッグ用モックデータ返却）
      return _getMockData();
    }
  }

  /// デバッグ/デモ用モックデータ
  static List<AppUsageData> _getMockData() {
    final today = DateTime.now();
    return [
      AppUsageData(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        usageTime: const Duration(minutes: 45),
        date: today,
      ),
      AppUsageData(
        packageName: 'com.twitter.android',
        appName: 'X (Twitter)',
        usageTime: const Duration(minutes: 32),
        date: today,
      ),
      AppUsageData(
        packageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        usageTime: const Duration(minutes: 28),
        date: today,
      ),
    ];
  }
}
