//
//  CalendarEvent.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/28.
//

import Foundation

/// Googleカレンダーから取得したイベント情報を表すデータモデル
///
/// Google Calendar APIのレスポンスを直接デコードするためCodableに準拠。
/// `CalendarEvent+Workout`拡張でトレーニングデータへの変換機能を提供する。
struct CalendarEvent: Identifiable, Codable {
    let id: String
    let summary: String?
    let start: EventDateTime?
    let end: EventDateTime?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id, summary, start, end, description
    }
}

/// Googleカレンダーイベントの日時情報
///
/// 時間指定イベント（`dateTime`）と終日イベント（`date`）の両方に対応する。
struct EventDateTime: Codable {
    let dateTime: String?  // 時間指定イベント
    let date: String?  // 終日イベント
    let timeZone: String?
}

/// Googleカレンダーイベントから解析したトレーニングデータ
///
/// `CalendarEvent.workoutData`で変換された種目・重量・セット・回数の情報を保持する。
struct WorkoutEventData {
    let exerciseName: String  // 種目
    let weight: String  // 重量(文字列でも可)
    let sets: Int
    let reps: Int
    let date: Date  // iOS内で扱う Date
}
