import 'dart:convert';
import 'package:http/http.dart' as http;

class AiMonitorService {
  static const String _baseUrl = 'https://your-api-id.execute-api.ap-northeast-1.amazonaws.com/prod';
  static bool _useDemoMode = true;

  static void setDemoMode(bool enabled) {
    _useDemoMode = enabled;
  }

  static Future<ScreenshotAnalysis> analyzeScreenshot({
    required String userId,
    required String imageBase64,
  }) async {
    if (_useDemoMode) return _getDemoAnalysis();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/analyze-screenshot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'image': imageBase64,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ScreenshotAnalysis.fromJson(data['analysis']);
      }
      return _getDemoAnalysis();
    } catch (e) {
      return _getDemoAnalysis();
    }
  }

  static Future<MonitorDecision> getRealtimeDecision({
    required String userId,
    required String currentApp,
    required int sessionMinutes,
    required int dailyTotalMinutes,
    required int limitMinutes,
    List<Map<String, dynamic>> usageHistory = const [],
  }) async {
    if (_useDemoMode) {
      return _getDemoDecision(dailyTotalMinutes, limitMinutes);
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/realtime-monitor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'currentApp': currentApp,
          'sessionMinutes': sessionMinutes,
          'dailyTotalMinutes': dailyTotalMinutes,
          'limitMinutes': limitMinutes,
          'usageHistory': usageHistory,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MonitorDecision.fromJson(data['decision']);
      }
      return _getDemoDecision(dailyTotalMinutes, limitMinutes);
    } catch (e) {
      return _getDemoDecision(dailyTotalMinutes, limitMinutes);
    }
  }

  static ScreenshotAnalysis _getDemoAnalysis() {
    return const ScreenshotAnalysis(
      appDetected: 'Instagram',
      isSns: true,
      activityType: 'スクロール',
      engagementLevel: 'high',
      suggestion: 'インスタをずっと見てるサイ！そろそろ閉じるサイ！',
    );
  }

  static MonitorDecision _getDemoDecision(int dailyTotal, int limit) {
    final ratio = dailyTotal / limit;
    if (ratio > 1.0) {
      return const MonitorDecision(
        interventionNeeded: true,
        urgency: 'critical',
        interventionType: 'strong_warning',
        message: '制限時間を超えてるサイ！今すぐスマホを置くサイ！',
        predictedBehavior: 'このままだと今日の使用時間が大幅に超過します',
        healthImpact: 'high',
      );
    } else if (ratio > 0.7) {
      return const MonitorDecision(
        interventionNeeded: true,
        urgency: 'medium',
        interventionType: 'gentle_reminder',
        message: 'そろそろ制限に近づいてるサイ…ペースダウンするサイ',
        predictedBehavior: 'このペースだと30分以内に制限を超過する可能性があります',
        healthImpact: 'medium',
      );
    } else {
      return const MonitorDecision(
        interventionNeeded: false,
        urgency: 'none',
        interventionType: 'none',
        message: 'いい調子サイ！この調子で頑張るサイ！',
        predictedBehavior: '現在のペースなら制限内に収まる見込みです',
        healthImpact: 'low',
      );
    }
  }
}

class ScreenshotAnalysis {
  final String appDetected;
  final bool isSns;
  final String activityType;
  final String engagementLevel;
  final String suggestion;

  const ScreenshotAnalysis({
    required this.appDetected,
    required this.isSns,
    required this.activityType,
    required this.engagementLevel,
    required this.suggestion,
  });

  factory ScreenshotAnalysis.fromJson(Map<String, dynamic> json) {
    return ScreenshotAnalysis(
      appDetected: json['app_detected'] ?? '不明',
      isSns: json['is_sns'] ?? false,
      activityType: json['activity_type'] ?? 'その他',
      engagementLevel: json['engagement_level'] ?? 'low',
      suggestion: json['suggestion'] ?? '',
    );
  }
}

class MonitorDecision {
  final bool interventionNeeded;
  final String urgency;
  final String interventionType;
  final String message;
  final String predictedBehavior;
  final String healthImpact;

  const MonitorDecision({
    required this.interventionNeeded,
    required this.urgency,
    required this.interventionType,
    required this.message,
    required this.predictedBehavior,
    required this.healthImpact,
  });

  factory MonitorDecision.fromJson(Map<String, dynamic> json) {
    return MonitorDecision(
      interventionNeeded: json['intervention_needed'] ?? false,
      urgency: json['urgency'] ?? 'none',
      interventionType: json['intervention_type'] ?? 'none',
      message: json['message'] ?? '',
      predictedBehavior: json['predicted_behavior'] ?? '',
      healthImpact: json['health_impact'] ?? 'low',
    );
  }
}
