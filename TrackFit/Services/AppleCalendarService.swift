//
//  AppleCalendarService.swift
//  TrackFit
//

import EventKit
import Foundation

/// Apple純正カレンダー（EventKit）との連携を管理するサービス
///
/// EKEventStoreを使用してカレンダーイベントのCRUD操作とパーミッション管理を行う。
/// Googleカレンダー連携と並行して動作する。
struct AppleCalendarService {

    // MARK: - Shared Event Store

    /// アプリ全体で共有するEKEventStoreインスタンス
    static let eventStore = EKEventStore()

    // MARK: - Permission

    /// カレンダーアクセス権限をリクエスト
    static func requestAccess() async throws -> Bool {
        return try await eventStore.requestFullAccessToEvents()
    }

    /// 現在のカレンダーアクセス権限ステータスを返す
    static var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    /// フルアクセスが許可されているかどうか
    static var hasFullAccess: Bool {
        authorizationStatus == .fullAccess
    }

    // MARK: - Calendar Selection

    /// ユーザーが書き込み可能なカレンダー一覧を取得
    static func writableCalendars() -> [EKCalendar] {
        eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
    }

    /// デフォルトカレンダーを取得
    static func defaultCalendar() -> EKCalendar? {
        eventStore.defaultCalendarForNewEvents
    }

    /// 保存されたカレンダーIDからEKCalendarを復元。見つからなければdefaultを返す
    static func calendar(forIdentifier identifier: String?) -> EKCalendar? {
        if let id = identifier, !id.isEmpty,
            let cal = eventStore.calendar(withIdentifier: id)
        {
            return cal
        }
        return defaultCalendar()
    }

    // MARK: - Create Event (DailyWorkout)

    /// DailyWorkoutからAppleカレンダーイベントを作成
    /// - Returns: 作成されたイベントのeventIdentifier
    static func createWorkoutEvent(
        workout: DailyWorkout,
        calendarIdentifier: String? = nil
    ) throws -> String {
        guard let calendar = calendar(forIdentifier: calendarIdentifier) else {
            throw AppleCalendarError.calendarNotFound
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "トレーニング"
        event.startDate = workout.startDate
        event.endDate = workout.endDate
        event.calendar = calendar
        event.notes = buildWorkoutDescription(workout: workout)

        try eventStore.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    // MARK: - Update Event (DailyWorkout)

    /// 既存のAppleカレンダーイベントを更新
    static func updateWorkoutEvent(
        eventIdentifier: String,
        workout: DailyWorkout,
        calendarIdentifier: String? = nil
    ) throws {
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            throw AppleCalendarError.eventNotFound
        }

        event.title = "トレーニング"
        event.startDate = workout.startDate
        event.endDate = workout.endDate
        event.notes = buildWorkoutDescription(workout: workout)

        if let calId = calendarIdentifier, !calId.isEmpty,
            let cal = eventStore.calendar(withIdentifier: calId)
        {
            event.calendar = cal
        }

        try eventStore.save(event, span: .thisEvent)
    }

    // MARK: - Create Event (RunningRecord)

    /// RunningRecordからAppleカレンダーイベントを作成
    /// - Returns: 作成されたイベントのeventIdentifier
    static func createRunningEvent(
        record: RunningRecord,
        calendarIdentifier: String? = nil
    ) throws -> String {
        guard let calendar = calendar(forIdentifier: calendarIdentifier) else {
            throw AppleCalendarError.calendarNotFound
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "ランニング（\(record.runType.rawValue)）"
        event.startDate = record.date
        event.endDate = record.date.addingTimeInterval(record.duration)
        event.calendar = calendar
        event.notes = buildRunningDescription(record: record)

        try eventStore.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    // MARK: - Update Event (RunningRecord)

    /// 既存のランニングイベントを更新
    static func updateRunningEvent(
        eventIdentifier: String,
        record: RunningRecord,
        calendarIdentifier: String? = nil
    ) throws {
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            throw AppleCalendarError.eventNotFound
        }

        event.title = "ランニング（\(record.runType.rawValue)）"
        event.startDate = record.date
        event.endDate = record.date.addingTimeInterval(record.duration)
        event.notes = buildRunningDescription(record: record)

        try eventStore.save(event, span: .thisEvent)
    }

    // MARK: - Private Helpers

    /// ワークアウト記録のdescriptionテキストを生成
    private static func buildWorkoutDescription(workout: DailyWorkout) -> String {
        workout.records.map { record in
            if record.isRunning {
                return """
                    種目: \(record.exerciseName)
                    距離: \(String(format: "%.2f", record.distance ?? 0)) km
                    時間: \(record.durationString)
                    """
            } else {
                return """
                    種目: \(record.exerciseName)
                    重量: \(String(format: "%.1f", record.weight ?? 0)) kg
                    セット数: \(record.sets ?? 0)
                    回数: \(record.reps ?? 0)
                    """
            }
        }.joined(separator: "\n\n")
    }

    /// ランニング記録のdescriptionテキストを生成
    private static func buildRunningDescription(record: RunningRecord) -> String {
        var lines: [String] = [
            "種別: \(record.runType.rawValue)",
            "距離: \(String(format: "%.2f", record.distance)) km",
            "時間: \(record.durationString)",
            "ペース: \(record.paceString)",
        ]
        if let memo = record.memo, !memo.isEmpty {
            lines.append("メモ: \(memo)")
        }
        return lines.joined(separator: "\n")
    }
}
