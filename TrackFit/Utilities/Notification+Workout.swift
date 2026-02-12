import Foundation

/// トレーニング記録の同期・連携に使用するカスタム通知名
extension Notification.Name {
    static let didStartSyncingWorkout = Notification.Name("didStartSyncingWorkout")
    static let didFinishSyncingWorkout = Notification.Name("didFinishSyncingWorkout")
    static let didFailSyncingWorkout = Notification.Name("didFailSyncingWorkout")
    static let shouldShowCalendarIntegrationAlert = Notification.Name(
        "shouldShowCalendarIntegrationAlert")
}
