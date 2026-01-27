# システムアーキテクチャ

TrackFitアプリのシステム構成とアーキテクチャについて説明します。

## システム構成図

```mermaid
flowchart TB
    subgraph iOS["iOS App (TrackFit)"]
        subgraph UI["Views Layer"]
            HomeView
            WorkoutRecordView
            TrainingHistoryView
            SettingView
        end
        subgraph VM["ViewModels Layer"]
            HomeViewModel
            WorkoutViewModel
            ExerciseViewModel
            CalendarViewModel
        end
        subgraph Data["Data Layer"]
            SwiftData[("SwiftData")]
            Keychain[("Keychain")]
        end
        subgraph Services["Services Layer"]
            GoogleCalendarAPI
            AdMobService
        end
    end

    subgraph External["External Services"]
        GoogleSignIn["Google Sign-In"]
        GoogleCalendar["Google Calendar API"]
        GoogleAdMob["Google AdMob"]
    end

    UI --> VM
    VM --> Data
    VM --> Services
    Services --> External
    GoogleCalendarAPI --> GoogleSignIn
    GoogleCalendarAPI --> GoogleCalendar
    AdMobService --> GoogleAdMob
```

## MVVMアーキテクチャ

TrackFitはMVVM（Model-View-ViewModel）パターンを採用しています。

```mermaid
flowchart LR
    subgraph View
        direction TB
        V1["SwiftUI Views"]
        V2["@State / @Binding"]
    end
    
    subgraph ViewModel
        direction TB
        VM1["@StateObject"]
        VM2["@Published properties"]
        VM3["ビジネスロジック"]
    end
    
    subgraph Model
        direction TB
        M1["SwiftData @Model"]
        M2["Data structs"]
    end

    View <--"データバインディング"--> ViewModel
    ViewModel <--"CRUD操作"--> Model
```

### 各レイヤーの責務

| レイヤー | 責務 | 主なファイル |
|----------|------|---------------|
| **View** | UI表示、ユーザー操作の受付 | `HomeView.swift`, `ContentView.swift` |
| **ViewModel** | ビジネスロジック、状態管理 | `HomeViewModel.swift`, `WorkoutViewModel.swift` |
| **Model** | データ構造、永続化 | `Exercise.swift`, `DailyWorkout.swift` |
| **Services** | 外部API連携 | `GoogleCalendarAPI.swift`, `AdMobService.swift` |

## 技術スタック

| カテゴリ | 技術 |
|----------|------|
| UIフレームワーク | SwiftUI |
| データ永続化 | SwiftData |
| 認証トークン保存 | Keychain |
| 外部認証 | Google Sign-In |
| カレンダー連携 | Google Calendar API |
| 広告 | Google AdMob |
| 最低サポートOS | iOS 18.0 |
| 言語 | Swift 6.0 |

## 関連Issue

- [Issue #123: システム構成図の作成](https://github.com/garyuu09/track-fit/issues/123)
