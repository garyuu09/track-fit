import Foundation
import Testing

@testable import TrackFit

struct DateHelperTests {

    // MARK: - formattedDate

    @Test func formattedDate_format() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let components = DateComponents(year: 2025, month: 6, day: 15, hour: 12, minute: 0)
        let date = calendar.date(from: components)!
        let result = DateHelper.formattedDate(date)
        #expect(result == "2025/06/15")
    }

    @Test func formattedDate_singleDigitMonth() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let components = DateComponents(year: 2025, month: 1, day: 5, hour: 12, minute: 0)
        let date = calendar.date(from: components)!
        let result = DateHelper.formattedDate(date)
        #expect(result == "2025/01/05")
    }

    // MARK: - formattedTime

    @Test func formattedTime_returnsNonEmpty() {
        let date = Date()
        let result = DateHelper.formattedTime(date)
        #expect(!result.isEmpty)
    }

    // MARK: - formattedDateTime

    @Test func formattedDateTime_containsDateAndTime() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let components = DateComponents(year: 2025, month: 6, day: 15, hour: 15, minute: 45)
        let date = calendar.date(from: components)!
        let result = DateHelper.formattedDateTime(date)
        #expect(result.contains("2025/06/15"))
        #expect(result.contains("15:45"))
    }

    // MARK: - formattedWorkoutPeriod

    @Test func formattedWorkoutPeriod_sameDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let startComponents = DateComponents(year: 2025, month: 6, day: 15, hour: 15, minute: 0)
        let endComponents = DateComponents(year: 2025, month: 6, day: 15, hour: 16, minute: 30)
        let start = calendar.date(from: startComponents)!
        let end = calendar.date(from: endComponents)!

        let result = DateHelper.formattedWorkoutPeriod(startDate: start, endDate: end)
        #expect(result.contains("2025/06/15"))
        #expect(result.contains("-"))
    }

    // MARK: - iso8601String

    @Test func iso8601String_format() {
        let date = Date(timeIntervalSince1970: 0)
        let result = DateHelper.iso8601String(from: date)
        #expect(result == "1970-01-01T00:00:00Z")
    }
}
