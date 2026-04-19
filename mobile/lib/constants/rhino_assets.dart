/// サイのキャラクター画像パスを一元管理するクラス。
/// 画像を差し替える場合はここのパスを変更するだけでOK。
class RhinoAssets {
  RhinoAssets._();

  static const String _base = 'assets/images/rhino';

  // ===== Home画面: ステータス別 =====
  static const String good = '$_base/rhino_good.png';
  static const String normal = '$_base/rhino_normal.png';
  static const String bad = '$_base/rhino_bad.png';

  // ===== 分析画面: 博士風（normalで代用） =====
  static const String doctor = '$_base/rhino_normal.png';

  // ===== ランキング画面: 闘争心（goodで代用） =====
  static const String fighter = '$_base/rhino_good.png';

  /// ステータスに応じた画像パスを返す
  static String fromStatus(RhinoStatus status) {
    switch (status) {
      case RhinoStatus.good:
        return good;
      case RhinoStatus.normal:
        return normal;
      case RhinoStatus.bad:
        return bad;
    }
  }

  /// ステータスに応じたコメントを返す
  static String commentFromStatus(RhinoStatus status) {
    switch (status) {
      case RhinoStatus.good:
        return 'いい調子サイ！この調子で頑張るサイ！';
      case RhinoStatus.normal:
        return 'そろそろ注意サイ…少し休憩しなサイ？';
      case RhinoStatus.bad:
        return '使いすぎサイ！スマホを置くサイ！';
    }
  }

  /// 全画像パスのリスト（プリキャッシュ用）
  static const List<String> all = [good, normal, bad, doctor, fighter];
}

/// サイの3状態
enum RhinoStatus { good, normal, bad }
