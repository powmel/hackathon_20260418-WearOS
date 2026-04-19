import 'package:flutter/services.dart';

/// バックグラウンド監視サービス（Android専用）
class MonitorService {
  static const _channel = MethodChannel('com.sabori.app/monitor');

  /// 監視を開始
  static Future<bool> startMonitoring({required int timeLimitMinutes}) async {
    try {
      final result = await _channel.invokeMethod<bool>('startMonitoring', {
        'timeLimit': timeLimitMinutes,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('監視開始エラー: $e');
      return false;
    }
  }

  /// 監視を停止
  static Future<bool> stopMonitoring() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopMonitoring');
      return result ?? false;
    } on PlatformException catch (e) {
      print('監視停止エラー: $e');
      return false;
    }
  }

  /// 監視中かどうか
  static Future<bool> isMonitoring() async {
    try {
      final result = await _channel.invokeMethod<bool>('isMonitoring');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
