import 'package:flutter/material.dart';

/// 監視対象SNSアプリ
class SnsApp {
  final String name;
  final String packageName;
  final IconData icon;
  final Color color;

  const SnsApp({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.color,
  });
}

final List<SnsApp> targetApps = [
  const SnsApp(
    name: 'Instagram',
    packageName: 'com.instagram.android',
    icon: Icons.camera_alt,
    color: Color(0xFFE1306C),
  ),
  const SnsApp(
    name: 'X (Twitter)',
    packageName: 'com.twitter.android',
    icon: Icons.tag,
    color: Color(0xFF1DA1F2),
  ),
  const SnsApp(
    name: 'TikTok',
    packageName: 'com.zhiliaoapp.musically',
    icon: Icons.music_note,
    color: Color(0xFF010101),
  ),
];

/// サイの性格モード
enum RhinoMode {
  strict, // きつめモード
  gentle, // ほんわかモード
  funny, // ネタモード
}

extension RhinoModeExtension on RhinoMode {
  String get label {
    switch (this) {
      case RhinoMode.strict:
        return 'きつめモード 🦏💢';
      case RhinoMode.gentle:
        return 'ほんわかモード 🦏💕';
      case RhinoMode.funny:
        return 'ネタモード 🦏🎭';
    }
  }

  String get description {
    switch (this) {
      case RhinoMode.strict:
        return '厳しい口調で叱ってくれます';
      case RhinoMode.gentle:
        return '優しく癒してくれます';
      case RhinoMode.funny:
        return '面白く注意してくれます';
    }
  }
}

/// きつめモード通知メッセージ
const strictMessages = [
  'いい加減にするサイ！🦏💢',
  'まだ見てるのかサイ？スマホを置けサイ！',
  'サボってる場合じゃないサイ！🦏',
  'やめろサイ！時間の無駄サイ！💢',
  'いつまでダラダラしてるサイ！🦏',
  'SNSを閉じるサイ！今すぐサイ！',
  'おい！集中しろサイ！🦏💢',
  '甘えるなサイ！スマホを置けサイ！',
];

/// ほんわかモード通知メッセージ
const gentleMessages = [
  '視聴をやめなサイ～🦏💕',
  'そろそろ休憩しなサイ？🦏',
  'スマホ、少しお休みしなサイ～💕',
  'がんばってるの知ってるサイ🦏✨',
  'ちょっとだけ我慢してみなサイ～',
  '一緒にがんばろうサイ🦏💕',
  'あなたなら大丈夫サイ～🦏',
  'SNS見すぎかもサイ？少し離れてみなサイ💕',
];

/// ネタモード通知メッセージ
const funnyMessages = [
  'サイは見た！あなたがまだSNSしてるのを🦏👀',
  'サイですか？いいえ、あなたのSNS警察サイ🚨',
  'まだ見てるのかサイ？サイレンならすサイよ？🚨🦏',
  'サイコーに無駄な時間過ごしてるサイね🦏',
  'サイの角でスマホ弾き飛ばすサイよ？🦏',
  'SNSをサイドに置くサイ！🦏',
  'サイきんSNS見すぎじゃなサイ？🦏🤔',
  'サイ能があるなら集中してみるサイ！🦏🧠',
];

/// デフォルト制限時間（分）
const int defaultTimeLimitMinutes = 30;

/// デフォルト通知間隔（分）
const int defaultNotificationIntervalMinutes = 5;

/// アプリテーマカラー - Stripe風デザイン
const Color primaryColor = Color(0xFF533AFD); // Stripe Purple
const Color accentColor = Color(0xFF533AFD); // Stripe Purple (CTA)
const Color secondaryColor = Color(0xFF4434D4); // Purple Hover
const Color questColor = Color(0xFFEA2261); // Ruby (decorative accent)
const Color expBarColor = Color(0xFF15BE53); // Success Green
const Color darkBg = Color(0xFF0D253D); // Dark Navy
const Color darkCard = Color(0xFF1C1E54); // Brand Dark
const Color lightBg = Color(0xFFFFFFFF); // Pure White
const Color woodBrown = Color(0xFF273951); // Label color
const Color stoneGray = Color(0xFF64748D); // Body text (slate)
const Color magicBlue = Color(0xFF2874AD); // Info blue
const Color rarityGold = Color(0xFFF96BEE); // Magenta accent
