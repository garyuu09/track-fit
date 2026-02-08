import Foundation
import Testing

@testable import TrackFit

@MainActor
struct RunningViewModelTests {

    // MARK: - totalDuration

    @Test func totalDuration_withAllComponents() {
        let vm = RunningViewModel()
        vm.hours = 1
        vm.minutes = 30
        vm.seconds = 45
        #expect(vm.totalDuration == 5445)  // 3600 + 1800 + 45
    }

    @Test func totalDuration_withZero() {
        let vm = RunningViewModel()
        #expect(vm.totalDuration == 0)
    }

    @Test func totalDuration_minutesOnly() {
        let vm = RunningViewModel()
        vm.minutes = 25
        #expect(vm.totalDuration == 1500)
    }

    // MARK: - paceString

    @Test func paceString_validInput() {
        let vm = RunningViewModel()
        vm.distance = 5.0
        vm.minutes = 25
        vm.seconds = 0
        // 1500秒 / 5km = 300秒/km = 5:00 /km
        #expect(vm.paceString == "5:00 /km")
    }

    @Test func paceString_zeroDistance() {
        let vm = RunningViewModel()
        vm.minutes = 30
        vm.distance = 0
        #expect(vm.paceString == "--:-- /km")
    }

    @Test func paceString_zeroDuration() {
        let vm = RunningViewModel()
        vm.distance = 5.0
        #expect(vm.paceString == "--:-- /km")
    }

    @Test func paceString_10km50min() {
        let vm = RunningViewModel()
        vm.distance = 10.0
        vm.minutes = 50
        // 3000秒 / 10km = 300秒/km = 5:00 /km
        #expect(vm.paceString == "5:00 /km")
    }

    // MARK: - isValidInput

    @Test func isValidInput_valid() {
        let vm = RunningViewModel()
        vm.distance = 5.0
        vm.minutes = 30
        #expect(vm.isValidInput == true)
    }

    @Test func isValidInput_noDistance() {
        let vm = RunningViewModel()
        vm.minutes = 30
        #expect(vm.isValidInput == false)
    }

    @Test func isValidInput_noDuration() {
        let vm = RunningViewModel()
        vm.distance = 5.0
        #expect(vm.isValidInput == false)
    }

    @Test func isValidInput_bothZero() {
        let vm = RunningViewModel()
        #expect(vm.isValidInput == false)
    }

    // MARK: - resetForm

    @Test func resetForm_clearsAllFields() {
        let vm = RunningViewModel()
        vm.distance = 10.0
        vm.hours = 1
        vm.minutes = 30
        vm.seconds = 45
        vm.selectedRunType = .tempo
        vm.memo = "テストメモ"

        vm.resetForm()

        #expect(vm.distance == 0.0)
        #expect(vm.hours == 0)
        #expect(vm.minutes == 0)
        #expect(vm.seconds == 0)
        #expect(vm.selectedRunType == .jog)
        #expect(vm.memo == "")
    }

    // MARK: - loadForEdit

    @Test func loadForEdit_setsAllFields() {
        let vm = RunningViewModel()
        let record = RunningRecord(
            date: Date(),
            distance: 5.5,
            duration: 1830,  // 30分30秒
            runType: .longRun,
            memo: "ロング走メモ"
        )

        vm.loadForEdit(record: record)

        #expect(vm.distance == 5.5)
        #expect(vm.hours == 0)
        #expect(vm.minutes == 30)
        #expect(vm.seconds == 30)
        #expect(vm.selectedRunType == .longRun)
        #expect(vm.memo == "ロング走メモ")
    }

    @Test func loadForEdit_withHours() {
        let vm = RunningViewModel()
        let record = RunningRecord(
            date: Date(),
            distance: 21.1,
            duration: 7200,  // 2時間
            runType: .race
        )

        vm.loadForEdit(record: record)

        #expect(vm.hours == 2)
        #expect(vm.minutes == 0)
        #expect(vm.seconds == 0)
    }
}
