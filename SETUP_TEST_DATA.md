# テストデータのセットアップ

## 現在の状態 ✅

ログから確認できたこと：
```
✅ Firebase初期化成功
✅ Firestoreリスナー起動（/users/test_user_001を監視中）
❌ ユーザードキュメントが存在しない
```

## 次のステップ: Firebase Consoleでテストデータ作成

### 1. Firebase Consoleにアクセス

https://console.firebase.google.com/project/hakkason-63f33/firestore/databases/-default-/data

### 2. テストユーザードキュメントを作成

1. **「コレクションを開始」をクリック**（まだusersコレクションがない場合）
   - コレクションID: `users`
   - 「次へ」をクリック

2. **ドキュメントを追加**
   - ドキュメントID: `test_user_001` （手動入力）
   - 以下のフィールドを追加:

```
フィールド名                  型          値
────────────────────────────────────────────
userId                    string      test_user_001
displayName               string      テストユーザー
todayTotalMinutes         number      45
timeLimitMinutes          number      180
usageRate                 number      25.0
weeklyTotalMinutes        number      320
streakDays                number      5
efficiencyScore           number      85.5
```

3. **rhinoStatusサブフィールドを追加**

   「rhinoStatus」フィールドを追加（型: map）:
   ```
   rhinoStatus (map)
     ├─ focusScore        number      80
     ├─ fullness          number      75
     ├─ mood              string      happy
     └─ lastUpdated       timestamp   [現在時刻]
   ```

4. **「保存」をクリック**

### 3. Wearアプリで確認

ドキュメント作成後、**1-2秒以内**にWearアプリのログに以下が表示されます:

```
[FirestoreSync] Data received: {...}
[FirestoreSync] Parsed: today=45min, limit=180min, rate=25.0%
[FirestoreSync] RhinoStatus: RhinoStatus(score: 80, fullness: 75, mood: happy, usage: 45min)
[WearOS] Firestore data update: UsageData(today: 45min, limit: 180min, rate: 25.0%)
[WearOS] 🔄 Updating UI - usageMinutes: 45
[WearOS] ✅ UI Updated - Circular gauge showing: 45 minutes
```

### 4. UIで視覚的に確認

Wearエミュレータの画面で:
- ✅ **外周に緑色の円形ゲージ**が表示される（進捗25%、45/180分）
- ✅ 画面下部に**「45分」**と表示される
- ✅ 上部のスコアバッジに**「80pt」**と表示される
- ✅ サイの元気度が**75%**

### 5. リアルタイム同期のテスト

Firebase Consoleで`todayTotalMinutes`を変更してみてください:

**変更前:**
```
todayTotalMinutes: 45
```

**変更後:**
```
todayTotalMinutes: 120
```

**期待される動作:**
1. 変更を保存すると**即座に**Wearアプリに反映
2. ログに表示:
   ```
   [FirestoreSync] Parsed: today=120min, ...
   [WearOS] 🔄 Updating UI - usageMinutes: 120
   ```
3. **円形ゲージが黄色に変化**（120分 = 67%進捗）
4. 画面下部が**「120分」**に更新

### 6. 色の変化をテスト

異なる使用時間で色が変わることを確認:

| usageMinutes | ゲージの色 | 進捗 |
|-------------|-----------|------|
| 30          | 🟢 緑     | 17%  |
| 60          | 🟡 黄色    | 33%  |
| 120         | 🟠 オレンジ | 67%  |
| 180以上     | 🔴 ピンク  | 100% |

## トラブルシューティング

### ログが表示されない

```bash
# ログファイルを確認
cat /tmp/wear_sync_test.log | grep -E "Firestore|WearOS"
```

### UIが更新されない

1. **ホットリロード**: エミュレータ画面で `r` キーを押す
2. **アプリ再起動**: `R` キー（大文字）で完全再起動

### Firebase Authエラーを修正

`firebase_options.dart`が正しく生成されていない場合:

```bash
# FlutterFire CLIで再生成
flutterfire configure --project=hakkason-63f33 --platforms=android
```

## 成功時のログ例

```
I/flutter: [WearOS] Firebase initialized successfully
I/flutter: [FirestoreSync] Initializing...
I/flutter: [FirestoreSync] Signed in anonymously
I/flutter: [FirestoreSync] Cognito User ID: null
I/flutter: [FirestoreSync] Using fallback test user ID for demo
I/flutter: [FirestoreSync] Starting to listen to /users/test_user_001
I/flutter: [WearOS] Firestore sync initialized
I/flutter: [FirestoreSync] Data received: {userId: test_user_001, ...}
I/flutter: [FirestoreSync] Parsed: today=45min, limit=180min, rate=25.0%
I/flutter: [FirestoreSync] RhinoStatus: RhinoStatus(score: 80, fullness: 75, mood: happy, usage: 45min)
I/flutter: [WearOS] Firestore data update: UsageData(today: 45min, limit: 180min, rate: 25.0%)
I/flutter: [WearOS] 🔄 Updating UI - usageMinutes: 45
I/flutter: [WearOS] ✅ UI Updated - Circular gauge showing: 45 minutes
```

---

## まとめ

現在の実装は**正常に動作しています**！

- ✅ Firebase接続成功
- ✅ Firestoreリスナー起動
- ✅ リアルタイム同期の準備完了
- ⚠️ テストデータの作成が必要

**次の作業**: Firebase Consoleで`users/test_user_001`ドキュメントを作成
