import Foundation
import Testing

@testable import TrackFit

@MainActor
struct HomeViewModelTests {

    // MARK: - Helper

    private func makeWorkout(daysAgo: Int) -> DailyWorkout {
        let date = Date().addingTimeInterval(TimeInterval(-daysAgo * 86400))
        return DailyWorkout(
            startDate: date,
            endDate: date.addingTimeInterval(3600),
            records: [],
            isSyncedToCalendar: false
        )
    }

    // MARK: - updateStats

    @Test func updateStats_emptyWorkouts() {
        let vm = HomeViewModel()
        vm.updateStats(workouts: [])

        #expect(vm.recentWorkouts.isEmpty)
        #expect(vm.currentWeekStreak == 0)
        #expect(vm.activityLog.isEmpty)
    }

    @Test func updateStats_recentWorkouts_limitsToFive() {
        let vm = HomeViewModel()
        var workouts: [DailyWorkout] = []
        for i in 0..<10 {
            workouts.append(makeWorkout(daysAgo: i))
        }
        vm.updateStats(workouts: workouts)

        #expect(vm.recentWorkouts.count == 5)
    }

    @Test func updateStats_recentWorkouts_sortedByDateDescending() {
        let vm = HomeViewModel()
        let older = makeWorkout(daysAgo: 3)
        let newer = makeWorkout(daysAgo: 0)
        vm.updateStats(workouts: [older, newer])

        #expect(vm.recentWorkouts.count == 2)
        #expect(vm.recentWorkouts.first?.startDate == newer.startDate)
    }

    // MARK: - activityLog

    @Test func activityLog_countsPerDay() {
        let vm = HomeViewModel()
        let today = Calendar.current.startOfDay(for: Date())
        let workout1 = DailyWorkout(
            startDate: today,
            endDate: today.addingTimeInterval(3600),
            records: [],
            isSyncedToCalendar: false
        )
        let workout2 = DailyWorkout(
            startDate: today.addingTimeInterval(7200),
            endDate: today.addingTimeInterval(10800),
            records: [],
            isSyncedToCalendar: false
        )
        vm.updateStats(workouts: [workout1, workout2])

        #expect(vm.activityLog[today] == 2)
    }

    @Test func activityLog_differentDays() {
        let vm = HomeViewModel()
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let workout1 = DailyWorkout(
            startDate: today,
            endDate: today.addingTimeInterval(3600),
            records: [],
            isSyncedToCalendar: false
        )
        let workout2 = DailyWorkout(
            startDate: yesterday,
            endDate: yesterday.addingTimeInterval(3600),
            records: [],
            isSyncedToCalendar: false
        )
        vm.updateStats(workouts: [workout1, workout2])

        #expect(vm.activityLog[today] == 1)
        #expect(vm.activityLog[yesterday] == 1)
    }

    // MARK: - streak

    @Test func streak_noWorkouts_returnsZero() {
        let vm = HomeViewModel()
        vm.updateStats(workouts: [])
        #expect(vm.currentWeekStreak == 0)
    }

    @Test func streak_workoutThisWeek_returnsAtLeastOne() {
        let vm = HomeViewModel()
        let today = Date()
        let workout = DailyWorkout(
            startDate: today,
            endDate: today.addingTimeInterval(3600),
            records: [],
            isSyncedToCalendar: false
        )
        vm.updateStats(workouts: [workout])
        #expect(vm.currentWeekStreak >= 1)
    }
}
