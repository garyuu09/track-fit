import Foundation
import Testing

@testable import TrackFit

@MainActor
struct WorkoutViewModelTests {

    // MARK: - 初期状態

    @Test func initialState_exerciseName() {
        let vm = WorkoutViewModel()
        #expect(vm.exerciseName == "")
    }

    @Test func initialState_weight() {
        let vm = WorkoutViewModel()
        #expect(vm.weight == "")
    }

    @Test func initialState_sets() {
        let vm = WorkoutViewModel()
        #expect(vm.sets == 1)
    }

    @Test func initialState_reps() {
        let vm = WorkoutViewModel()
        #expect(vm.reps == 10)
    }

    @Test func initialState_eventId() {
        let vm = WorkoutViewModel()
        #expect(vm.eventId == nil)
    }

    @Test func initialState_errorMessage() {
        let vm = WorkoutViewModel()
        #expect(vm.errorMessage == nil)
    }

    @Test func initialState_isLoading() {
        let vm = WorkoutViewModel()
        #expect(vm.isLoading == false)
    }

    // MARK: - updateEvent

    @Test func updateEvent_nilEventId_returnsFalse() async {
        let vm = WorkoutViewModel()
        let workout = DailyWorkout(
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            records: [],
            isSyncedToCalendar: false
        )
        // eventIdがnilのworkoutでupdateEventを呼ぶとfalseが返る
        let result = await vm.updateEvent(dailyWorkout: workout)
        #expect(result == false)
    }

    @Test func updateEvent_nilEventId_setsErrorMessage() async {
        let vm = WorkoutViewModel()
        let workout = DailyWorkout(
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            records: [],
            isSyncedToCalendar: false
        )
        _ = await vm.updateEvent(dailyWorkout: workout)
        #expect(vm.errorMessage == "イベントIDが取得できません。")
    }
}
