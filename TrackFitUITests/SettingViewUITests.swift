//
//  SettingViewUITests.swift
//  TrackFitUITests
//
//  設定画面のUIテスト
//

import XCTest

final class SettingViewUITests: XCTestCase {
    var app: XCUIApplication!
    var settingPage: SettingPage!
    var tabBar: TabBar!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        settingPage = SettingPage(app: app)
        tabBar = TabBar(app: app)

        // 設定タブへ移動
        tabBar.tapSettingTab()
        XCTAssertTrue(settingPage.waitForPageLoad())
    }

    override func tearDownWithError() throws {
        app = nil
        settingPage = nil
        tabBar = nil
    }

    // MARK: - 表示テスト

    @MainActor
    func testSettingViewIsDisplayed() throws {
        // Then: 設定画面が表示される
        XCTAssertTrue(settingPage.isDisplayed, "設定画面が表示されるべき")
    }

    @MainActor
    func testSettingContainsExpectedSections() throws {
        // Then: 設定画面には期待されるセクションが表示される
        let hasThemeText = app.staticTexts["テーマカラー"].exists
        let hasExerciseText = app.staticTexts["種目管理"].exists
        XCTAssertTrue(hasThemeText || hasExerciseText, "設定項目が表示されるべき")
    }

    @MainActor
    func testExerciseManagementButtonExists() throws {
        // Then: 種目管理ボタンが存在する
        XCTAssertTrue(settingPage.exerciseManagementButton.exists, "種目管理ボタンが表示されるべき")
    }

    // MARK: - ナビゲーションテスト

    @MainActor
    func testNavigateBackToHome() throws {
        // When: ホームタブをタップ
        tabBar.tapHomeTab()

        // Then: ホーム画面に戻る
        let homePage = HomePage(app: app)
        XCTAssertTrue(homePage.waitForPageLoad(), "ホーム画面に戻るべき")
    }
}
