//
//  UserFlowUITests.swift
//  TrackFitUITests
//
//  ユーザーフロー（E2E）のUIテスト
//

import XCTest

final class UserFlowUITests: XCTestCase {
    var app: XCUIApplication!
    var tabBar: TabBar!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        sleep(1)

        tabBar = TabBar(app: app)
    }

    override func tearDownWithError() throws {
        app = nil
        tabBar = nil
    }

    // MARK: - ワークアウト画面の操作フローテスト

    @MainActor
    func testWorkoutFilterAndTypeToggle() throws {
        // トレーニング記録画面へ移動
        tabBar.tapWorkoutTab()
        let workoutPage = WorkoutRecordPage(app: app)
        XCTAssertTrue(workoutPage.waitForPageLoad())

        // フィルター切替
        workoutPage.selectLastWeek()
        XCTAssertTrue(workoutPage.isDisplayed)

        workoutPage.selectThisMonth()
        XCTAssertTrue(workoutPage.isDisplayed)

        workoutPage.selectAllPeriod()
        XCTAssertTrue(workoutPage.isDisplayed)

        workoutPage.selectThisWeek()
        XCTAssertTrue(workoutPage.isDisplayed)

        // ワークアウト種別切替
        workoutPage.selectRunning()
        XCTAssertTrue(workoutPage.isDisplayed)

        workoutPage.selectWeightTraining()
        XCTAssertTrue(workoutPage.isDisplayed)
    }
}
