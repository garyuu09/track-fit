import Foundation
import Testing

@testable import TrackFit

@MainActor
struct CalendarViewModelTests {

    // MARK: - 初期状態

    @Test func initialState_eventsIsEmpty() {
        let vm = CalendarViewModel()
        #expect(vm.events.isEmpty)
    }

    @Test func initialState_isLoadingIsFalse() {
        let vm = CalendarViewModel()
        #expect(vm.isLoading == false)
    }

    @Test func initialState_errorMessageIsNil() {
        let vm = CalendarViewModel()
        #expect(vm.errorMessage == nil)
    }
}
