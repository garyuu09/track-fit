import Foundation
import Testing

@testable import TrackFit

struct GoogleCalendarAPITests {

    // MARK: - buildWorkoutEventBody

    @Test func buildWorkoutEventBody_summary() {
        let workout = DailyWorkout(
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            records: [],
            isSyncedToCalendar: false
        )
        let body = GoogleCalendarAPI.buildWorkoutEventBody(workout: workout, colorId: "4")
        #expect(body["summary"] as? String == "トレーニング")
    }

    @Test func buildWorkoutEventBody_colorId() {
        let workout = DailyWorkout(
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            records: [],
            isSyncedToCalendar: false
        )
        let body = GoogleCalendarAPI.buildWorkoutEventBody(workout: workout, colorId: "11")
        #expect(body["colorId"] as? String == "11")
    }

    @Test func buildWorkoutEventBody_startDateTime() {
        let startDate = Date()
        let workout = DailyWorkout(
            startDate: startDate,
            endDate: startDate.addingTimeInterval(3600),
            records: [],
            isSyncedToCalendar: false
        )
        let body = GoogleCalendarAPI.buildWorkoutEventBody(workout: workout, colorId: "4")
        let start = body["start"] as? [String: String]
        #expect(start?["dateTime"] == DateHelper.iso8601String(from: startDate))
        #expect(start?["timeZone"] == "UTC")
    }

    @Test func buildWorkoutEventBody_endDateTime() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600)
        let workout = DailyWorkout(
            startDate: startDate,
            endDate: endDate,
            records: [],
            isSyncedToCalendar: false
        )
        let body = GoogleCalendarAPI.buildWorkoutEventBody(workout: workout, colorId: "4")
        let end = body["end"] as? [String: String]
        #expect(end?["dateTime"] == DateHelper.iso8601String(from: endDate))
        #expect(end?["timeZone"] == "UTC")
    }

    @Test func buildWorkoutEventBody_emptyRecords() {
        let workout = DailyWorkout(
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            records: [],
            isSyncedToCalendar: false
        )
        let body = GoogleCalendarAPI.buildWorkoutEventBody(workout: workout, colorId: "4")
        #expect(body["description"] as? String == "")
    }

    @Test func buildWorkoutEventBody_singleRecord() {
        let record = WorkoutRecord(exerciseName: "ベンチプレス", weight: 60.0, reps: 10, sets: 3)
        let workout = DailyWorkout(
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            records: [record],
            isSyncedToCalendar: false
        )
        let body = GoogleCalendarAPI.buildWorkoutEventBody(workout: workout, colorId: "4")
        let description = body["description"] as? String ?? ""
        #expect(description.contains("ベンチプレス"))
        #expect(description.contains("60.0"))
        #expect(description.contains("10"))
        #expect(description.contains("3"))
    }

    @Test func buildWorkoutEventBody_multipleRecords() {
        let records = [
            WorkoutRecord(exerciseName: "ベンチプレス", weight: 60.0, reps: 10, sets: 3),
            WorkoutRecord(exerciseName: "スクワット", weight: 80.0, reps: 8, sets: 4),
        ]
        let workout = DailyWorkout(
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            records: records,
            isSyncedToCalendar: false
        )
        let body = GoogleCalendarAPI.buildWorkoutEventBody(workout: workout, colorId: "4")
        let description = body["description"] as? String ?? ""
        #expect(description.contains("ベンチプレス"))
        #expect(description.contains("スクワット"))
    }

    // MARK: - validateResponse

    @Test func validateResponse_200_noThrow() throws {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(
            url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let data = Data()
        #expect(throws: Never.self) {
            try GoogleCalendarAPI.validateResponse(response, data: data)
        }
    }

    @Test func validateResponse_201_noThrow() throws {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(
            url: url, statusCode: 201, httpVersion: nil, headerFields: nil)!
        let data = Data()
        #expect(throws: Never.self) {
            try GoogleCalendarAPI.validateResponse(response, data: data)
        }
    }

    @Test func validateResponse_299_noThrow() throws {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(
            url: url, statusCode: 299, httpVersion: nil, headerFields: nil)!
        let data = Data()
        #expect(throws: Never.self) {
            try GoogleCalendarAPI.validateResponse(response, data: data)
        }
    }

    @Test func validateResponse_400_throws() {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(
            url: url, statusCode: 400, httpVersion: nil, headerFields: nil)!
        let data = "Bad Request".data(using: .utf8)!
        #expect(throws: CalendarAPIError.self) {
            try GoogleCalendarAPI.validateResponse(response, data: data)
        }
    }

    @Test func validateResponse_401_throws() {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(
            url: url, statusCode: 401, httpVersion: nil, headerFields: nil)!
        let data = "Unauthorized".data(using: .utf8)!
        #expect(throws: CalendarAPIError.self) {
            try GoogleCalendarAPI.validateResponse(response, data: data)
        }
    }

    @Test func validateResponse_500_throws() {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(
            url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
        let data = "Server Error".data(using: .utf8)!
        #expect(throws: CalendarAPIError.self) {
            try GoogleCalendarAPI.validateResponse(response, data: data)
        }
    }

    @Test func validateResponse_errorContainsStatusCodeAndBody() {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(
            url: url, statusCode: 403, httpVersion: nil, headerFields: nil)!
        let body = "Forbidden"
        let data = body.data(using: .utf8)!
        do {
            try GoogleCalendarAPI.validateResponse(response, data: data)
            Issue.record("Expected error to be thrown")
        } catch let error as CalendarAPIError {
            if case .httpError(let statusCode, let errorBody) = error {
                #expect(statusCode == 403)
                #expect(errorBody == "Forbidden")
            } else {
                Issue.record("Expected httpError case")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - EventsResponse decoding

    @Test func eventsResponse_decodesCorrectly() throws {
        let json = """
            {
                "items": [
                    {
                        "id": "event1",
                        "summary": "トレーニング",
                        "description": "テスト",
                        "start": {"dateTime": "2025-01-01T10:00:00Z"},
                        "end": {"dateTime": "2025-01-01T11:00:00Z"}
                    }
                ]
            }
            """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(GoogleCalendarAPI.EventsResponse.self, from: data)
        #expect(decoded.items.count == 1)
        #expect(decoded.items[0].id == "event1")
        #expect(decoded.items[0].summary == "トレーニング")
    }

    @Test func eventsResponse_emptyItems() throws {
        let json = """
            {"items": []}
            """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(GoogleCalendarAPI.EventsResponse.self, from: data)
        #expect(decoded.items.isEmpty)
    }

    @Test func eventsResponse_multipleItems() throws {
        let json = """
            {
                "items": [
                    {"id": "e1", "summary": "A"},
                    {"id": "e2", "summary": "B"},
                    {"id": "e3", "summary": "C"}
                ]
            }
            """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(GoogleCalendarAPI.EventsResponse.self, from: data)
        #expect(decoded.items.count == 3)
    }
}
