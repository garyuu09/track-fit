import Foundation

extension Notification.Name {
    static let didStartSyncingWorkout = Notification.Name("didStartSyncingWorkout")
    static let didFinishSyncingWorkout = Notification.Name("didFinishSyncingWorkout")
    static let shouldShowCalendarIntegrationAlert = Notification.Name(
        "shouldShowCalendarIntegrationAlert")
}
