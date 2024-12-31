//
//  GoogleCalendarAPI.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/28.
//
import Foundation

struct GoogleCalendarAPI {
    // APIのレスポンス全体
    struct EventsResponse: Codable {
        let items: [CalendarEvent]
    }

    static func fetchEvents(accessToken: String) async throws -> [CalendarEvent] {
        // プライマリカレンダーのイベントを取得する
        guard let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events?maxResults=20&orderBy=startTime&singleEvents=true&orderBy=startTime&timeMin=2024-01-01T00%3A00%3A00Z&timeMax=2024-02-01T00%3A00%3A00Z") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // async/await で通信
        let (data, response) = try await URLSession.shared.data(for: request)

        // ステータスコードチェック (例)
        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            print("Status Code:", httpResponse.statusCode)
            throw URLError(.badServerResponse)
        }
        print("Response body:", String(data: data, encoding: .utf8) ?? "N/A")

        // JSONデコード
        let decoded = try JSONDecoder().decode(EventsResponse.self, from: data)
        return decoded.items
    }

    static func createEvent(accessToken: String, event: CalendarEvent) async throws {
        guard let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events") else {
            throw URLError(.badURL)
        }
    }
}
