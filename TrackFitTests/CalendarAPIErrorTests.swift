import Foundation
import Testing

@testable import TrackFit

struct CalendarAPIErrorTests {

    // MARK: - errorDescription

    @Test func invalidURL_errorDescription() {
        let error = CalendarAPIError.invalidURL
        #expect(error.errorDescription == "無効なURLです")
    }

    @Test func httpError_errorDescription() {
        let error = CalendarAPIError.httpError(statusCode: 404, body: "Not Found")
        #expect(error.errorDescription == "APIエラー (404)\nNot Found")
    }

    @Test func httpError_serverError() {
        let error = CalendarAPIError.httpError(statusCode: 500, body: "Internal Server Error")
        #expect(error.errorDescription == "APIエラー (500)\nInternal Server Error")
    }

    @Test func tokenNotFound_errorDescription() {
        let error = CalendarAPIError.tokenNotFound
        #expect(error.errorDescription == "アクセストークンが見つかりません")
    }

    @Test func tokenExpired_errorDescription() {
        let error = CalendarAPIError.tokenExpired
        #expect(error.errorDescription == "アクセストークンの期限が切れています")
    }

    @Test func refreshFailed_errorDescription() {
        let underlying = NSError(
            domain: "test", code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "refresh error"
            ])
        let error = CalendarAPIError.refreshFailed(underlying: underlying)
        #expect(error.errorDescription?.contains("トークン更新に失敗しました") == true)
        #expect(error.errorDescription?.contains("refresh error") == true)
    }

    // MARK: - LocalizedError conformance

    @Test func conformsToLocalizedError() {
        let error: any LocalizedError = CalendarAPIError.invalidURL
        #expect(error.errorDescription != nil)
    }
}
