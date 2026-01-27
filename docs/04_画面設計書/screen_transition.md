# 画面遷移図

TrackFitアプリの画面遷移を示します。

## メイン画面遷移

```mermaid
flowchart TB
    subgraph TabBar["タブバー"]
        direction LR
        HomeTab["ホーム"]
        WorkoutTab["トレーニング記録"]
        HistoryTab["履歴"]
        SettingTab["設定"]
    end

    HomeTab --> HomeView["ホーム画面"]
    WorkoutTab --> WorkoutRecordView["トレーニング記録画面"]
    HistoryTab --> TrainingHistoryView["トレーニング履歴画面"]
    SettingTab --> SettingView["設定画面"]

    WorkoutRecordView --> ExerciseSelectionView["種目選択画面"]
    WorkoutRecordView --> WorkoutEditView["ワークアウト編集画面"]
    
    TrainingHistoryView --> ExerciseDetailView["種目詳細画面"]
    TrainingHistoryView --> WorkoutCalendarHistoryView["カレンダー履歴画面"]
    
    SettingView --> ExerciseManagementView["種目管理画面"]
    SettingView --> GoogleCalendarIntegrationView["カレンダー連携画面"]
    SettingView --> PrivacyPolicyView["プライバシーポリシー"]

    ExerciseManagementView --> ExerciseSelectionView
```

## タブ構成

| タブ | アイコン | メインView | 説明 |
|------|---------|----------|------|
| ホーム | `house` | HomeView | 統計情報、ヒートマップ表示 |
| トレーニング記録 | `timer` | WorkoutRecordView | ワークアウトの新規記録 |
| 履歴 | `magnifyingglass` | TrainingHistoryView | 過去の記録一覧 |
| 設定 | `gearshape` | SettingView | アプリ設定 |

## 関連Issue

- [Issue #124: 画面設計書の作成](https://github.com/garyuu09/track-fit/issues/124)
