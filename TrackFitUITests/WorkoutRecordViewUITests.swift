//
//  WorkoutRecordViewUITests.swift
//  TrackFitUITests
//
//  トレーニング記録画面のUIテスト
//

import XCTest

final class WorkoutRecordViewUITests: XCTestCase {
    var app: XCUIApplication!
    var workoutPage: WorkoutRecordPage!
    var tabBar: TabBar!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        sleep(1)

        workoutPage = WorkoutRecordPage(app: app)
        tabBar = TabBar(app: app)

        // トレーニング記録タブへ移動
        tabBar.tapWorkoutTab()
        XCTAssertTrue(workoutPage.waitForPageLoad())
    }

    override func tearDownWithError() throws {
        app = nil
        workoutPage = nil
        tabBar = nil
    }

    // MARK: - 表示テスト

    @MainActor
    func testWorkoutRecordViewIsDisplayed() throws {
        // Then: トレーニング記録画面が表示される
        XCTAssertTrue(workoutPage.isDisplayed, "トレーニング記録画面が表示されるべき")
    }

    @MainActor
    func testPeriodFilterPickerExists() throws {
        // Then: 期間フィルターPickerが存在する
        XCTAssertTrue(workoutPage.thisWeekFilter.exists, "今週フィルターが表示されるべき")
        XCTAssertTrue(workoutPage.lastWeekFilter.exists, "先週フィルターが表示されるべき")
        XCTAssertTrue(workoutPage.thisMonthFilter.exists, "今月フィルターが表示されるべき")
        XCTAssertTrue(workoutPage.allFilter.exists, "全てフィルターが表示されるべき")
    }

    @MainActor
    func testWorkoutTypePickerExists() throws {
        // Then: ワークアウト種別Pickerが存在する
        XCTAssertTrue(workoutPage.weightTrainingType.exists, "筋トレタイプが表示されるべき")
        XCTAssertTrue(workoutPage.runningType.exists, "ランニングタイプが表示されるべき")
    }

    @MainActor
    func testAddButtonExists() throws {
        // Then: 追加ボタンが存在する
        XCTAssertTrue(workoutPage.addTrainingButton.exists, "追加ボタンが表示されるべき")
    }

    // MARK: - フィルター切替テスト

    @MainActor
    func testSwitchPeriodFilter() throws {
        // When: 先週フィルターをタップ
        workoutPage.selectLastWeek()

        // Then: 画面がクラッシュせず表示される
        XCTAssertTrue(workoutPage.isDisplayed)

        // When: 今月フィルターをタップ
        workoutPage.selectThisMonth()

        // Then: 画面がクラッシュせず表示される
        XCTAssertTrue(workoutPage.isDisplayed)
    }

    // MARK: - ワークアウト種別切替テスト

    @MainActor
    func testSwitchWorkoutType() throws {
        // Given: 初期状態は筋トレ
        XCTAssertTrue(workoutPage.weightTrainingType.exists)

        // When: ランニングに切替
        workoutPage.selectRunning()

        // Then: 画面がクラッシュせず表示される
        XCTAssertTrue(workoutPage.isDisplayed)

        // When: 筋トレに戻す
        workoutPage.selectWeightTraining()

        // Then: 画面がクラッシュせず表示される
        XCTAssertTrue(workoutPage.isDisplayed)
    }
}
