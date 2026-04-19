# Sabori App - サボり防止アプリ

SNS使用時間を監視してサイが警告するアプリ。スマホ + Wear OS 連携。

## 構成

```
mobile/   ← Androidスマホアプリ (Flutter + Riverpod)
wear/     ← Wear OSアプリ (Flutter, たまごっち風UI)
shared/   ← 共通データモデル (Dartパッケージ)
```

## mobile/ (スマホアプリ)
- SNS使用時間のリアルタイム監視
- サイキャラが反応 (good / warning / over)
- 30日間の使用傾向分析
- ランキング機能
- Firebase + AWS Cognito 認証

## wear/ (Wear OSアプリ)
- たまごっち風の部屋でサイペットを飼育
- Tinder風グラデーションUI
- スコアでエサやり、服変更
- バイブレーション & 通知機能
- ペットの気分で部屋の雰囲気が変化

## shared/ (共通モデル)
- PetState: ペット状態 (スコア, 使用時間, 元気, 気分, 服)
- SyncMessage: phone↔watch通信メッセージ
- Constants: 共通定数
