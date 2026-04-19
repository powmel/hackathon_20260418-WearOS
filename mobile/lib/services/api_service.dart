import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_usage.dart';

class ApiService {
  static const String _baseUrl = 'https://your-api-id.execute-api.ap-northeast-1.amazonaws.com/prod';
  static bool _useDemoMode = true;

  static void setDemoMode(bool enabled) {
    _useDemoMode = enabled;
  }

  static bool get isDemoMode => _useDemoMode;

  static Future<List<UserRankingData>> getRankings({String sortBy = 'efficiencyScore'}) async {
    if (_useDemoMode) return _getDemoRankings(sortBy);

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/rankings?sortBy=$sortBy'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserRankingData.fromJson(json as Map<String, dynamic>)).toList();
      }
      return _getDemoRankings(sortBy);
    } catch (e) {
      return _getDemoRankings(sortBy);
    }
  }

  static Future<bool> submitScore({
    required String userId,
    required String displayName,
    required int weeklyTotalMinutes,
    required int streakDays,
    required double efficiencyScore,
  }) async {
    if (_useDemoMode) return true;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rankings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'displayName': displayName,
          'weeklyTotalMinutes': weeklyTotalMinutes,
          'streakDays': streakDays,
          'efficiencyScore': efficiencyScore,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> submitUsageData({
    required String userId,
    required List<AppUsageData> usages,
  }) async {
    if (_useDemoMode) return true;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/usage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'usages': usages.map((u) => u.toJson()).toList(),
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> submitChallenge({
    required String userId,
    required Challenge challenge,
  }) async {
    if (_useDemoMode) return true;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/challenges'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          ...challenge.toJson(),
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ── Device Registration (Push Notifications) ──

  static Future<bool> registerDevice({
    required String userId,
    required String token,
    String platform = 'android',
  }) async {
    if (_useDemoMode) return true;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/devices/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'token': token,
          'platform': platform,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Demo Data ──

  static List<UserRankingData> _getDemoRankings(String sortBy) {
    final List<UserRankingData> data = [
      const UserRankingData(userId: 'user_001', displayName: 'サイ太郎', weeklyTotalMinutes: 85, streakDays: 14, efficiencyScore: 92.4),
      const UserRankingData(userId: 'user_002', displayName: 'ホーン花子', weeklyTotalMinutes: 120, streakDays: 10, efficiencyScore: 85.1),
      const UserRankingData(userId: 'user_003', displayName: '角の助', weeklyTotalMinutes: 150, streakDays: 7, efficiencyScore: 78.8),
      const UserRankingData(userId: 'user_you', displayName: 'あなた', weeklyTotalMinutes: 180, streakDays: 5, efficiencyScore: 72.3),
      const UserRankingData(userId: 'user_004', displayName: 'リノ次郎', weeklyTotalMinutes: 210, streakDays: 3, efficiencyScore: 65.0),
      const UserRankingData(userId: 'user_005', displayName: 'SNS大好き子', weeklyTotalMinutes: 275, streakDays: 2, efficiencyScore: 51.7),
      const UserRankingData(userId: 'user_006', displayName: 'まったり勢', weeklyTotalMinutes: 290, streakDays: 1, efficiencyScore: 44.2),
      const UserRankingData(userId: 'user_007', displayName: 'タイムイーター', weeklyTotalMinutes: 320, streakDays: 1, efficiencyScore: 38.5),
      const UserRankingData(userId: 'user_008', displayName: 'ながらスマホ', weeklyTotalMinutes: 365, streakDays: 0, efficiencyScore: 30.9),
      const UserRankingData(userId: 'user_009', displayName: 'エンドレス太郎', weeklyTotalMinutes: 390, streakDays: 0, efficiencyScore: 25.3),
      const UserRankingData(userId: 'user_010', displayName: '通知の奴隷', weeklyTotalMinutes: 410, streakDays: 0, efficiencyScore: 22.1),
      const UserRankingData(userId: 'user_011', displayName: 'スマホの虫', weeklyTotalMinutes: 450, streakDays: 0, efficiencyScore: 15.6),
    ];

    switch (sortBy) {
      case 'weeklyTotalMinutes':
        data.sort((a, b) => a.weeklyTotalMinutes.compareTo(b.weeklyTotalMinutes));
        break;
      case 'streakDays':
        data.sort((a, b) => b.streakDays.compareTo(a.streakDays));
        break;
      default:
        data.sort((a, b) => b.efficiencyScore.compareTo(a.efficiencyScore));
    }

    return data;
  }
}
