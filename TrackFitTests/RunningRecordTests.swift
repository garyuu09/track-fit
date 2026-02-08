import Foundation
import Testing

@testable import TrackFit

struct RunningRecordTests {

    // MARK: - paceString

    @Test func paceString_5minPerKm() {
        let record = RunningRecord(
            date: Date(),
            distance: 10.0,
            duration: 3000,  // 50分 → 300秒/km
            runType: .jog
        )
        #expect(record.paceString == "5:00 /km")
    }

    @Test func paceString_withSeconds() {
        let record = RunningRecord(
            date: Date(),
            distance: 5.0,
            duration: 1650,  // 27分30秒 → 330秒/km = 5:30
            runType: .tempo
        )
        #expect(record.paceString == "5:30 /km")
    }

    @Test func paceString_zeroDistance() {
        let record = RunningRecord(
            date: Date(),
            distance: 0,
            duration: 1800,
            runType: .jog
        )
        #expect(record.paceString == "--:-- /km")
    }

    // MARK: - durationString

    @Test func durationString_minutesOnly() {
        let record = RunningRecord(
            date: Date(),
            distance: 5.0,
            duration: 1800,  // 30分
            runType: .jog
        )
        #expect(record.durationString == "30:00")
    }

    @Test func durationString_withHours() {
        let record = RunningRecord(
            date: Date(),
            distance: 21.1,
            duration: 5400,  // 1時間30分
            runType: .longRun
        )
        #expect(record.durationString == "1:30:00")
    }

    @Test func durationString_withSeconds() {
        let record = RunningRecord(
            date: Date(),
            distance: 5.0,
            duration: 1830,  // 30分30秒
            runType: .jog
        )
        #expect(record.durationString == "30:30")
    }

    // MARK: - paceMinutesPerKm

    @Test func paceMinutesPerKm_calculated() {
        let record = RunningRecord(
            date: Date(),
            distance: 10.0,
            duration: 3000,  // 50分
            runType: .jog
        )
        #expect(record.paceMinutesPerKm == 5.0)
    }

    @Test func paceMinutesPerKm_zeroDistance() {
        let record = RunningRecord(
            date: Date(),
            distance: 0,
            duration: 1800,
            runType: .jog
        )
        #expect(record.paceMinutesPerKm == 0)
    }

    // MARK: - runType

    @Test func runType_getSet() {
        let record = RunningRecord(
            date: Date(),
            distance: 5.0,
            duration: 1500,
            runType: .jog
        )
        #expect(record.runType == .jog)
        #expect(record.runTypeRawValue == "ジョグ")

        record.runType = .interval
        #expect(record.runType == .interval)
        #expect(record.runTypeRawValue == "インターバル")
    }

    // MARK: - Initialization

    @Test func init_setsDefaultValues() {
        let record = RunningRecord(
            date: Date(),
            distance: 5.0,
            duration: 1500,
            runType: .jog
        )
        #expect(record.isSyncedToCalendar == false)
        #expect(record.eventId == nil)
        #expect(record.calories == nil)
        #expect(record.averageHeartRate == nil)
        #expect(record.memo == nil)
    }

    @Test func init_withOptionalValues() {
        let record = RunningRecord(
            date: Date(),
            distance: 10.0,
            duration: 3000,
            runType: .race,
            calories: 500,
            averageHeartRate: 160,
            memo: "レースメモ"
        )
        #expect(record.calories == 500)
        #expect(record.averageHeartRate == 160)
        #expect(record.memo == "レースメモ")
    }
}
