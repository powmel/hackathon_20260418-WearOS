import 'dart:convert';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../constants/app_constants.dart';

/// 通知サービス（Android専用 + FCM）
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final _random = Random();

  /// 初期化
  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        print('通知タップ: ${response.payload}');
        _handleNotificationTap(response.payload);
      },
    );
  }

  /// 通知権限リクエスト
  static Future<bool> requestPermission() async {
    // FCM権限
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized;

    // Android ローカル通知権限
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }

    return granted;
  }

  /// FCMトークンを取得
  static Future<String?> registerToken() async {
    try {
      // 初回起動直後は FIS/FCM 側が一時的に unavailable を返すことがある。
      final token = await _messaging.getToken();
      if (token != null) {
        print('FCM トークン: $token');
        await _sendTokenToServer(token);
      }

      _messaging.onTokenRefresh.listen((newToken) {
        print('トークン更新: $newToken');
        _sendTokenToServer(newToken);
      });

      return token;
    } catch (e) {
      print('FCM トークン取得失敗: $e');
    }

    return null;
  }

  /// サーバーにトークンを送信（TODO: 実装）
  static Future<void> _sendTokenToServer(String token) async {
    // TODO: APIエンドポイントに送信
    print('トークン送信（未実装）: $token');
  }

  /// FCM通知リスナーを設定
  static Future<void> setupFCMListeners() async {
    // フォアグラウンド受信
    FirebaseMessaging.onMessage.listen((message) {
      print('フォアグラウンド受信: ${message.notification?.title}');
      _showNotificationFromRemote(message);
    });

    // バックグラウンド → タップで復帰
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('通知タップで復帰: ${message.data}');
      _handleRemoteNotificationTap(message);
    });

    // 終了状態 → タップで起動
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteNotificationTap(initialMessage);
    }
  }

  /// FCM通知をローカル通知として表示
  static void _showNotificationFromRemote(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'fcm_channel',
      'プッシュ通知',
      channelDescription: 'サーバーからのプッシュ通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    _plugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Web用の通知表示（スタブ - Androidでは未使用）
  static void _showWebNotification(String title, String body) {
    print('Web通知はこのプラットフォームではサポートされていません: $title');
  }

  /// FCM通知タップ処理
  static void _handleRemoteNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    print('通知タイプ: $type');
    // TODO: 画面遷移
  }

  /// ローカル通知タップ処理
  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      print('通知データ: $data');
      // TODO: 画面遷移
    } catch (e) {
      print('エラー: $e');
    }
  }

  /// サイの警告通知
  static Future<void> showRhinoNotification({
    required RhinoMode mode,
    String? appName,
  }) async {
    final message = _getRandomMessage(mode);
    final title = appName != null ? '$appNameの使いすぎサイ！🦏' : 'SNS使いすぎサイ！🦏';

    const androidDetails = AndroidNotificationDetails(
      'rhino_alert',
      'サイの警告通知',
      channelDescription: 'SNS使用時間超過の警告通知',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin.show(
      _random.nextInt(10000),
      title,
      message,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// 日次レポート通知
  static Future<void> showDailyReportNotification({
    required Duration totalUsage,
    required int overLimitCount,
  }) async {
    final hours = totalUsage.inHours;
    final minutes = totalUsage.inMinutes % 60;

    const androidDetails = AndroidNotificationDetails(
      'daily_report',
      '日次レポート',
      channelDescription: '1日のSNS使用時間レポート',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.show(
      99999,
      '📊 今日のSNSレポートサイ！',
      '合計使用時間: ${hours}時間${minutes}分 / 制限超過: $overLimitCount回',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// ランダムメッセージ取得
  static String _getRandomMessage(RhinoMode mode) {
    final List<String> messages;
    switch (mode) {
      case RhinoMode.strict:
        messages = strictMessages;
      case RhinoMode.gentle:
        messages = gentleMessages;
      case RhinoMode.funny:
        messages = funnyMessages;
    }
    return messages[_random.nextInt(messages.length)];
  }
}
