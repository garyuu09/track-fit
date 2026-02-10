//
//  GoogleCalendarAPI.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/28.
//

import Foundation

/// Google Calendar APIのCRUD操作を担当するサービス
///
/// イベントの取得・作成・更新を行う。
/// 認証トークンの管理は`GoogleAuthService`、エラー型は`CalendarAPIError`に分離。
struct GoogleCalendarAPI {

    // MARK: - Response Types

    struct EventsResponse: Codable {
        let items: [CalendarEvent]
    }

    private struct CreateEventResponse: Decodable {
        let id: String
    }

    // MARK: - Public API

    /// カレンダーイベントを取得
    static func fetchEvents(accessToken: String) async throws -> [CalendarEvent] {
        return try await makeAPICallWithAutoRefresh { token in
            return try await performFetchEvents(accessToken: token)
        }
    }

    /// 新規イベントを作成
    /// - Returns: 作成されたイベントのID
    static func createWorkoutEvent(
        accessToken: String,
        workout: DailyWorkout,
        colorId: String = "4"
    ) async throws -> String {
        return try await makeAPICallWithAutoRefresh { token in
            return try await performCreateWorkoutEvent(
                accessToken: token, workout: workout, colorId: colorId)
        }
    }

    /// 既存イベントを更新
    static func updateWorkoutEvent(
        accessToken: String,
        eventId: String,
        workout: DailyWorkout,
        colorId: String = "4"
    ) async throws {
        return try await makeAPICallWithAutoRefresh { token in
            return try await performUpdateWorkoutEvent(
                accessToken: token, eventId: eventId, workout: workout, colorId: colorId)
        }
    }

    // MARK: - Auto-Refresh Helper

    /// 自動リトライ機能付きのAPI呼び出しヘルパー
    static func makeAPICallWithAutoRefresh<T>(_ apiCall: @escaping (String) async throws -> T)
        async throws -> T
    {
        let accessToken =
            KeychainHelper.shared.loadString(forKey: KeychainHelper.GoogleTokenKeys.accessToken)
            ?? ""

        do {
            return try await apiCall(accessToken)
        } catch {
            if let nsError = error as NSError?,
                nsError.code == 401 || GoogleAuthService.isTokenExpired()
            {
                #if DEBUG
                    print("認証エラーを検出、トークンを更新してリトライします")
                #endif
                let newToken = try await GoogleAuthService.refreshAccessToken()
                return try await apiCall(newToken)
            }
            throw error
        }
    }

    // MARK: - Private Implementation

    private static func performFetchEvents(accessToken: String) async throws -> [CalendarEvent] {
        guard
            let url = URL(
                string:
                    "https://www.googleapis.com/calendar/v3/calendars/primary/events?maxResults=20&orderBy=startTime&singleEvents=true&orderBy=startTime&timeMin=2024-01-01T00%3A00%3A00Z&timeMax=2024-02-01T00%3A00%3A00Z"
            )
        else {
            throw CalendarAPIError.invalidURL
        }

        let (data, response) = try await performRequest(
            url: url, method: "GET", accessToken: accessToken)
        try validateResponse(response, data: data)

        #if DEBUG
            print("Response body:", String(data: data, encoding: .utf8) ?? "N/A")
        #endif

        let decoded = try JSONDecoder().decode(EventsResponse.self, from: data)
        return decoded.items
    }

    private static func performCreateWorkoutEvent(
        accessToken: String,
        workout: DailyWorkout,
        colorId: String
    ) async throws -> String {
        guard
            let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")
        else {
            throw CalendarAPIError.invalidURL
        }

        let requestBody = buildWorkoutEventBody(workout: workout, colorId: colorId)
        let requestData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

        let (data, response) = try await performRequest(
            url: url, method: "POST", accessToken: accessToken, body: requestData)
        try validateResponse(response, data: data)

        let decoded = try JSONDecoder().decode(CreateEventResponse.self, from: data)
        return decoded.id
    }

    private static func performUpdateWorkoutEvent(
        accessToken: String,
        eventId: String,
        workout: DailyWorkout,
        colorId: String
    ) async throws {
        guard
            let url = URL(
                string: "https://www.googleapis.com/calendar/v3/calendars/primary/events/\(eventId)"
            )
        else {
            throw CalendarAPIError.invalidURL
        }

        let requestBody = buildWorkoutEventBody(workout: workout, colorId: colorId)
        let requestData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

        let (data, response) = try await performRequest(
            url: url, method: "PATCH", accessToken: accessToken, body: requestData)
        try validateResponse(response, data: data)
    }

    // MARK: - Shared Helpers

    /// 共通のHTTPリクエスト実行
    private static func performRequest(
        url: URL, method: String, accessToken: String, body: Data? = nil
    ) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if body != nil {
            request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        return try await URLSession.shared.data(for: request)
    }

    /// 共通のレスポンスバリデーション
    static func validateResponse(_ response: URLResponse, data: Data) throws {
        if let httpResponse = response as? HTTPURLResponse,
            !(200..<300).contains(httpResponse.statusCode)
        {
            let bodyString = String(data: data, encoding: .utf8) ?? "N/A"
            throw CalendarAPIError.httpError(statusCode: httpResponse.statusCode, body: bodyString)
        }
    }

    /// ワークアウトイベントのリクエストボディを生成
    static func buildWorkoutEventBody(workout: DailyWorkout, colorId: String)
        -> [String: Any]
    {
        let startString = DateHelper.iso8601String(from: workout.startDate)
        let endString = DateHelper.iso8601String(from: workout.endDate)

        let descriptionText = workout.records.map { record in
            """
            種目: \(record.exerciseName)
            重量: \(record.weight) kg
            セット数: \(record.sets)
            回数: \(record.reps)
            """
        }.joined(separator: "\n\n")

        return [
            "summary": "トレーニング",
            "description": descriptionText,
            "start": [
                "dateTime": startString,
                "timeZone": "UTC",
            ],
            "end": [
                "dateTime": endString,
                "timeZone": "UTC",
            ],
            "colorId": colorId,
        ]
    }
}
