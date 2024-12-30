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

    enum CodingKeys: String, CodingKey {
        case id, summary, start, end
    }
}

struct EventDateTime: Codable {
    let dateTime: String?   // 時間指定イベント
    let date: String?       // 終日イベント
    let timeZone: String?
}
