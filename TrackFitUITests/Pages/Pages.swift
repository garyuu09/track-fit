//
//  Pages.swift
//  TrackFitUITests
//
//  PageObjectパターンによる画面要素の抽象化
//

import XCTest

// MARK: - Base Page

/// 全ページの基底クラス
class BasePage {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    /// 要素の存在を待機
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    /// アクセシビリティ識別子で要素を検索（any type）
    func element(identifier: String) -> XCUIElement {
        return app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}

// MARK: - Tab Bar

/// タブバーのPageObject
class TabBar: BasePage {
    var homeTab: XCUIElement { app.buttons["ホーム"] }
    var workoutTab: XCUIElement { app.buttons["トレーニング記録"] }
    var settingTab: XCUIElement { app.buttons["設定"] }

    func tapHomeTab() {
        homeTab.tap()
    }

    func tapWorkoutTab() {
        workoutTab.tap()
    }

    func tapSettingTab() {
        settingTab.tap()
    }
}

// MARK: - Home Page

/// ホーム画面のPageObject
class HomePage: BasePage {
    var navigationTitle: XCUIElement { app.navigationBars["ホーム"] }
    var streakCard: XCUIElement { element(identifier: "streakCard") }
    var activityHeatmap: XCUIElement { element(identifier: "activityHeatmap") }
    var recentActivitySection: XCUIElement { element(identifier: "recentActivitySection") }
    var emptyRecentActivity: XCUIElement { element(identifier: "emptyRecentActivity") }

    var isDisplayed: Bool {
        return navigationTitle.exists
    }

    func waitForPageLoad(timeout: TimeInterval = 5) -> Bool {
        return waitForElement(navigationTitle, timeout: timeout)
    }
}

// MARK: - Workout Record Page

/// トレーニング記録画面のPageObject
class WorkoutRecordPage: BasePage {
    var navigationTitle: XCUIElement { app.navigationBars["トレーニング一覧"] }
    var periodFilterPicker: XCUIElement { element(identifier: "periodFilterPicker") }
    var workoutTypePicker: XCUIElement { element(identifier: "workoutTypePicker") }
    var workoutList: XCUIElement { element(identifier: "workoutList") }
    var addTrainingButton: XCUIElement { element(identifier: "addTrainingButton") }

    // フィルターボタン
    var thisWeekFilter: XCUIElement { app.buttons["今週"] }
    var lastWeekFilter: XCUIElement { app.buttons["先週"] }
    var thisMonthFilter: XCUIElement { app.buttons["今月"] }
    var allFilter: XCUIElement { app.buttons["全て"] }

    // ワークアウト種別ボタン
    var weightTrainingType: XCUIElement { app.buttons["筋トレ"] }
    var runningType: XCUIElement { app.buttons["ランニング"] }

    var isDisplayed: Bool {
        return navigationTitle.exists
    }

    func waitForPageLoad(timeout: TimeInterval = 5) -> Bool {
        return waitForElement(navigationTitle, timeout: timeout)
    }

    func selectThisWeek() {
        thisWeekFilter.tap()
    }

    func selectLastWeek() {
        lastWeekFilter.tap()
    }

    func selectThisMonth() {
        thisMonthFilter.tap()
    }

    func selectAllPeriod() {
        allFilter.tap()
    }

    func selectWeightTraining() {
        weightTrainingType.tap()
    }

    func selectRunning() {
        runningType.tap()
    }

    func tapAddButton() {
        addTrainingButton.tap()
    }
}

// MARK: - Setting Page

/// 設定画面のPageObject
class SettingPage: BasePage {
    var navigationTitle: XCUIElement { app.navigationBars["設定"] }
    var themeColorPicker: XCUIElement { element(identifier: "themeColorPicker") }
    var exerciseManagementButton: XCUIElement { app.staticTexts["種目管理"] }
    var versionInfo: XCUIElement { element(identifier: "versionInfo") }

    var isDisplayed: Bool {
        return navigationTitle.exists
    }

    func waitForPageLoad(timeout: TimeInterval = 5) -> Bool {
        return waitForElement(navigationTitle, timeout: timeout)
    }

    func tapExerciseManagement() {
        exerciseManagementButton.tap()
    }
}
