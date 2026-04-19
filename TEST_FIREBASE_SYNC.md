# Firebase同期のテスト手順

## 前提条件
- Wearアプリが起動している（emulator-5556）
- Firebase Console: https://console.firebase.google.com/project/hakkason-63f33/firestore

## テスト手順

### 1. SharedPreferencesにユーザーIDを設定

Wearアプリで使用するCognitoユーザーIDを設定します。

```dart
// wear/lib/main.dart の main() 関数に追加してテスト:
final prefs = await SharedPreferences.getInstance();
await prefs.setString('cognito_user_id', 'test_user_001');  // テスト用ID
```

または、Android Debug Bridge (adb)で設定:
```bash
adb -s emulator-5556 shell "run-as com.powmel.saiwear sh -c 'echo \"test_user_001\" > /data/data/com.powmel.saiwear/shared_prefs/FlutterSharedPreferences.xml'"
```

### 2. Firestoreにテストデータを作成

Firebase Console > Firestore Database で以下のドキュメントを作成:

```
Collection: users
Document ID: test_user_001

Fields:
{
  "userId": "test_user_001",
  "displayName": "テストユーザー",
  "todayTotalMinutes": 45,
  "timeLimitMinutes": 180,
  "usageRate": 25.0,
  "weeklyTotalMinutes": 320,
  "streakDays": 5,
  "efficiencyScore": 85.5,
  "rhinoStatus": {
    "focusScore": 80,
    "fullness": 75,
    "mood": "happy",
    "lastUpdated": [現在時刻]
  }
}
```

### 3. ログで同期を確認

Wearアプリを起動したターミナルで以下のログが表示されるはずです:

```
[FirestoreSync] Initializing...
[FirestoreSync] Signed in anonymously
[FirestoreSync] Cognito User ID: test_user_001
[FirestoreSync] Starting to listen to /users/test_user_001
[FirestoreSync] Data received: {...}
[FirestoreSync] Parsed: today=45min, limit=180min, rate=25.0%
[WearOS] Firestore data update: UsageData(today: 45min, limit: 180min, rate: 25.0%)
```

### 4. UIで確認

Wearアプリの画面で:
- 外周に**円形ゲージ**が表示される（緑色、進捗25%）
- 画面下部に「**45分**」と表示される
- スコアバッジに「**80pt**」と表示される

### 5. リアルタイム同期のテスト

Firebase Consoleで`todayTotalMinutes`を変更:
```
45 → 120
```

Wearアプリの画面が即座に更新されるはずです:
- 円形ゲージが黄色に変化
- 画面下部が「**120分**」に更新
- ゲージの進捗が約67%に

### 6. トラブルシューティング

#### ログが表示されない場合

**原因1: Cognito User IDが設定されていない**
```
[FirestoreSync] ERROR: No Cognito User ID found
```
→ SharedPreferencesにユーザーIDを設定

**原因2: Firestoreドキュメントが存在しない**
```
[FirestoreSync] User document does not exist
```
→ Firebase Consoleでドキュメントを作成

**原因3: Firebase初期化エラー**
```
[WearOS] Firebase initialization error: ...
```
→ `google-services.json`が正しく配置されているか確認
→ `firebase_options.dart`が生成されているか確認

#### 円形ゲージが表示されない場合

1. `_buildPetPage`に`_CircularUsageGauge`が追加されているか確認
2. `_state.usageMinutes`が正しく更新されているか確認（printデバッグ）
3. ホットリロード（`r`キー）を試す

## ログの確認方法

### Flutter DevTools
```bash
flutter run -d emulator-5556
# ブラウザで DevTools が開く → Logging タブ
```

### Android Studio Logcat
1. View > Tool Windows > Logcat
2. Filter: "flutter"または"FirestoreSync"

### コマンドライン
```bash
flutter logs -d emulator-5556 | grep -E "Firestore|WearOS"
```

## 期待される動作

✅ Wearアプリ起動時にFirestore初期化
✅ Cognito User IDでユーザードキュメントを監視
✅ データ変更時にリアルタイムで`onDataUpdate`コールバック実行
✅ UIが自動更新（円形ゲージ、分表示、スコア）
✅ 色分け: 緑(0-60分) → 黄(60-120分) → オレンジ(120-180分) → ピンク(180分以上)

## デモ用のクイック設定

匿名認証を使ってすぐにテストする場合:

```dart
// wear/lib/firestore_sync_service.dart の init() に追加:
if (_cognitoUserId == null) {
  // フォールバック: デモ用
  _cognitoUserId = 'test_user_001';
  _startListening();
}
```

これで、SharedPreferencesの設定なしでもFirestoreから読み取れます。
