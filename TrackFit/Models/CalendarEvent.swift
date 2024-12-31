//
//  CalendarEvent.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/28.
//

import Foundation

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

struct EventDateTime: Codable {
    let dateTime: String?   // 時間指定イベント
    let date: String?       // 終日イベント
    let timeZone: String?
}

// Workout(トレーニング)用の独自データ
struct WorkoutEventData {
    let exerciseName: String  // 種目
    let weight: String        // 重量(文字列でも可)
    let sets: Int
    let reps: Int
    let date: Date            // iOS内で扱う Date
}
