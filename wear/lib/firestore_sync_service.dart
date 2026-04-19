import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestoreからモバイルアプリのデータをリアルタイムで取得するサービス
class FirestoreSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;

  String? _cognitoUserId;
  Function(UsageData)? onDataUpdate;
  Function(RhinoStatusData)? onRhinoStatusUpdate;

  /// 初期化してCognito User IDを取得
  Future<void> init() async {
    print('[FirestoreSync] Initializing...');

    // Firebase匿名認証
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
        print('[FirestoreSync] Signed in anonymously');
      }
    } catch (e) {
      print('[FirestoreSync] Auth error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    _cognitoUserId = prefs.getString('cognito_user_id');
    print('[FirestoreSync] Cognito User ID: $_cognitoUserId');

    if (_cognitoUserId != null) {
      _startListening();
    } else {
      print('[FirestoreSync] ERROR: No Cognito User ID found');
      print('[FirestoreSync] Using fallback test user ID for demo');
      // フォールバック: テスト用のデフォルトユーザーID
      _cognitoUserId = 'test_user_001';
      _startListening();
    }
  }

  /// Firestoreのリアルタイムリスナーを開始
  void _startListening() {
    if (_cognitoUserId == null) return;

    print('[FirestoreSync] Starting to listen to /users/$_cognitoUserId');

    _userDataSubscription = _firestore
        .collection('users')
        .doc(_cognitoUserId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists) {
          print('[FirestoreSync] User document does not exist');
          return;
        }

        final data = snapshot.data();
        if (data == null) {
          print('[FirestoreSync] No data in document');
          return;
        }

        print('[FirestoreSync] Data received: $data');

        final usageData = UsageData(
          todayMinutes: data['todayTotalMinutes'] as int? ?? 0,
          limitMinutes: data['timeLimitMinutes'] as int? ?? 180,
          usageRate: (data['usageRate'] as num?)?.toDouble() ?? 0.0,
          displayName: data['displayName'] as String? ?? '名前未設定',
          weeklyMinutes: data['weeklyTotalMinutes'] as int? ?? 0,
          streakDays: data['streakDays'] as int? ?? 0,
          efficiencyScore: (data['efficiencyScore'] as num?)?.toDouble() ?? 0.0,
        );

        print('[FirestoreSync] Parsed: today=${usageData.todayMinutes}min, limit=${usageData.limitMinutes}min, rate=${usageData.usageRate}%');

        // コールバックでデータを通知
        onDataUpdate?.call(usageData);

        // rhinoStatusも取得
        final rhinoStatus = data['rhinoStatus'] as Map<String, dynamic>?;
        if (rhinoStatus != null) {
          final rhinoData = RhinoStatusData(
            focusScore: rhinoStatus['focusScore'] as int? ?? 0,
            fullness: rhinoStatus['fullness'] as int? ?? 50,
            mood: rhinoStatus['mood'] as String? ?? 'calm',
            usageMinutes: data['todayTotalMinutes'] as int? ?? 0,
          );
          print('[FirestoreSync] RhinoStatus: $rhinoData');
          onRhinoStatusUpdate?.call(rhinoData);
        }
      },
      onError: (error) {
        print('[FirestoreSync] ERROR: $error');
      },
    );
  }

  /// リスナーを停止
  void dispose() {
    _userDataSubscription?.cancel();
  }
}

/// モバイルアプリから受信するデータモデル
class UsageData {
  final int todayMinutes;
  final int limitMinutes;
  final double usageRate;
  final String displayName;
  final int weeklyMinutes;
  final int streakDays;
  final double efficiencyScore;

  UsageData({
    required this.todayMinutes,
    required this.limitMinutes,
    required this.usageRate,
    required this.displayName,
    required this.weeklyMinutes,
    required this.streakDays,
    required this.efficiencyScore,
  });

  @override
  String toString() {
    return 'UsageData(today: ${todayMinutes}min, limit: ${limitMinutes}min, rate: ${usageRate.toStringAsFixed(1)}%)';
  }
}

/// サイのステータスデータ
class RhinoStatusData {
  final int focusScore;
  final int fullness;
  final String mood;
  final int usageMinutes;

  RhinoStatusData({
    required this.focusScore,
    required this.fullness,
    required this.mood,
    required this.usageMinutes,
  });

  @override
  String toString() {
    return 'RhinoStatus(score: $focusScore, fullness: $fullness, mood: $mood, usage: ${usageMinutes}min)';
  }
}
