# TrackFit 🏋️‍♂️


TrackFitは、日々の筋力トレーニングを手軽に記録し、Googleカレンダーと連携して可視化できるiOSフィットネスアプリです。

<img src="https://github.com/user-attachments/assets/bfe312b9-2ff9-4db6-9676-eed4038469a0" width="15%">
<img src="https://github.com/user-attachments/assets/1f1ac444-9615-4d41-b294-a984688e6863" width="15%">
<img src="https://github.com/user-attachments/assets/4baddfde-2d86-4903-8057-b2f4ec7cf8c9" width="15%">
<img src="https://github.com/user-attachments/assets/50b15e72-f0b8-471b-926f-89d7ba295a47" width="15%">
<img src="https://github.com/user-attachments/assets/7715acfb-3bb8-4ada-82c2-e1a2e74a8e8f" width="15%">
<img src="https://github.com/user-attachments/assets/c747c591-214b-45a7-9adf-c0454f62020b" width="15%">

## 📱 システム要件

- iOS 18.0以上
- Xcode 16.0以上
- Swift 6.0

## ✨ 主な機能

- **トレーニング記録**: 日々のワークアウト（種目、重量、回数、セット数）を簡単に追加・編集できます。
- **Googleカレンダー連携**: 記録したトレーニングをGoogleカレンダーに自動で登録・更新し、スケジュール上でトレーニング履歴を振り返ることができます。
- **種目管理**: トレーニング種目を自由にカスタマイズ（追加・編集・削除）できます。カテゴリ別に管理することも可能です。
- **履歴表示**: 過去のトレーニング記録をリスト形式やカレンダー形式で直感的に確認できます。
- **テーマ設定**: ライトモード、ダークモード、システム設定に応じた表示切り替えに対応しています。

## 🛠️ 使用技術

- **UI**: SwiftUI
- **データベース**: SwiftData
- **API**: Google Calendar API, Google AdMob
- **認証**: Google Sign-In for iOS
- **設定管理**: Xcode Configuration (`.xcconfig`) によるAPIキーの分離

## 🏗️ アーキテクチャ

- **MVVM パターン**: SwiftUIとの親和性を活かした設計
- **SwiftData**: Core Dataの後継として採用
- **キーチェーン**: 認証トークンの安全な保存
- **Swift Testing**: 新しいテストフレームワークを採用

### プロジェクト構造
```
TrackFit/
├── Models/          # SwiftDataモデル
├── Views/           # SwiftUI画面
├── ViewModels/      # ViewModel層
├── Services/        # API連携
└── Utilities/       # ヘルパー関数
```

## 🔧 開発情報

### コードフォーマット
- Swift-formatが自動実行されます（ビルド時）
- 手動実行: `xcrun swift-format format --in-place --recursive TrackFit/`
- 設定: `.swift-format`ファイル参照

### テスト
- Swift Testing フレームワークを使用
- 実行: `⌘+U` または Xcode Test Navigator

## 📝 セットアップ手順

本プロジェクトをビルド・実行するには、いくつかのAPIキーを設定する必要があります。

1. **リポジトリをクローン**
   ```bash
   git clone https://github.com/YOUR_USERNAME/TrackFit.git
   cd TrackFit
   ```

2. **Google Cloud Platformでプロジェクトを作成**
   - [Google Cloud Console](https://console.cloud.google.com/)にアクセスし、新規プロジェクトを作成します。
   - **Google Calendar API** を有効にします。
   - **OAuth 2.0 クライアントID** を作成します。
     - アプリケーションの種類は「iOS」を選択します。
     - バンドルID (例: `com.yourcompany.trackfit`) を入力します。実際にはあなた独自のBundle IDを使用してください。
     - 作成された「クライアントID」と「逆引きクライアントID」を控えておきます。

3. **AdMobでアプリをセットアップ**
   - [Google AdMob](https://admob.google.com/)にアクセスし、新しいiOSアプリを登録します。
   - アプリIDと、バナー広告ユニットIDを作成し、控えておきます。

4. **`Secrets.xcconfig` ファイルの作成**
   - プロジェクトのルートディレクトリ（`TrackFit/`直下）に `Secrets.xcconfig` という名前のファイルを作成します。
   - 以下の内容をファイルに記述し、`//`以降を自分のキーに置き換えてください。

   ```
   // Google OAuth
   CLIENT_ID = com.googleusercontent.apps.xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   REVERSED_CLIENT_ID = com.googleusercontent.apps.xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

   // Google AdMob
   ADMOB_APP_ID = ca-app-pub-xxxxxxxxxxxxxxxx~xxxxxxxxxx
   ADMOB_BANNER_UNIT_ID_PROD = ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx
   ADMOB_BANNER_UNIT_ID_TEST = ca-app-pub-3940256099942544/2934735716
   ```

5. **Xcodeでプロジェクトを開く**
   - `.xcworkspace` ファイルを開いてください（`.xcodeproj` ではありません）。
   - ターゲットのビルド設定で、`Secrets.xcconfig`が正しく紐付いていることを確認してください。

6. **ビルドと実行**
   - Xcodeでビルドを実行し、シミュレータまたは実機でアプリを起動します。

## 📜 ライセンス

This project is licensed under the MIT License.
