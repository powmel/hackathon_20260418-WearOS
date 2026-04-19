import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// サイの鳴き声効果音サービス
class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  /// サイの鳴き声を再生
  static Future<void> playRhinoSound() async {
    // Web環境では音声再生をスキップ
    if (kIsWeb) return;

    try {
      await _player.play(AssetSource('sounds/rhino_sound.mp3'));
    } catch (e) {
      // 音声ファイルが見つからない場合はシステム音で代替
      try {
        await _player.play(AssetSource('sounds/notification.mp3'));
      } catch (_) {
        // 音声再生失敗時は無視
      }
    }
  }

  /// 再生停止
  static Future<void> stop() async {
    await _player.stop();
  }

  /// リソース解放
  static Future<void> dispose() async {
    await _player.dispose();
  }
}
