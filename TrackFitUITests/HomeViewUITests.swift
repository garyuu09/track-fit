//
//  HomeViewUITests.swift
//  TrackFitUITests
//
//  ホーム画面のUIテスト
//

import XCTest

final class HomeViewUITests: XCTestCase {
    var app: XCUIApplication!
    var homePage: HomePage!
    var tabBar: TabBar!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        sleep(1)

        homePage = HomePage(app: app)
        tabBar = TabBar(app: app)
    }

    override func tearDownWithError() throws {
        app = nil
        homePage = nil
        tabBar = nil
    }

    // MARK: - 表示テスト

    @MainActor
    func testHomeViewIsDisplayed() throws {
        // Given: アプリ起動時
        // Then: ホーム画面が表示される
        XCTAssertTrue(homePage.waitForPageLoad(), "ホーム画面が表示されるべき")
        XCTAssertTrue(homePage.isDisplayed)
    }

    @MainActor
    func testHomeContainsExpectedContent() throws {
        // Given: ホーム画面
        XCTAssertTrue(homePage.waitForPageLoad())

        // Then: ホーム画面には何らかのコンテンツが表示される
        // 「継続中」または「最近のアクティビティ」文字があることを確認
        let hasStreakText = app.staticTexts["継続中"].exists
        let hasRecentActivityText = app.staticTexts["最近のアクティビティ"].exists
        XCTAssertTrue(hasStreakText || hasRecentActivityText, "ホーム画面にコンテンツが表示されるべき")
    }

    // MARK: - ナビゲーションテスト

    @MainActor
    func testNavigateToWorkoutFromHomeTab() throws {
        // Given: ホーム画面
        XCTAssertTrue(homePage.waitForPageLoad())

        // When: トレーニング記録タブをタップ
        tabBar.tapWorkoutTab()

        // Then: トレーニング記録画面に遷移
        let workoutPage = WorkoutRecordPage(app: app)
        XCTAssertTrue(workoutPage.waitForPageLoad(), "トレーニング記録画面に遷移するべき")
    }
}
