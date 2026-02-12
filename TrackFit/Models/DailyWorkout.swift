//
//  DailyWorkout.swift
//  TrackFit
//
//  Created by Ryuga on 2025/03/22.
//

import Foundation
import SwiftData

/// 1日分のトレーニング記録を表すSwiftDataモデル
///
/// 特定の日に実施した全てのワークアウト（筋トレ・ランニング）をまとめて管理する。
/// Googleカレンダーとの同期状態も保持する。
@Model
class DailyWorkout: Identifiable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var eventId: String?
    var appleEventId: String?

    // その日実施したトレーニング一覧
    var records: [WorkoutRecord]

    // Googleカレンダー連携済みかどうか
    var isSyncedToCalendar: Bool = false
    // Appleカレンダー連携済みかどうか
    var isSyncedToAppleCalendar: Bool = false

    init(
        startDate: Date, endDate: Date, records: [WorkoutRecord], eventId: String? = nil,
        appleEventId: String? = nil,
        isSyncedToCalendar: Bool = false,
        isSyncedToAppleCalendar: Bool = false
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.records = records
        self.eventId = eventId
        self.appleEventId = appleEventId
        self.isSyncedToCalendar = isSyncedToCalendar
        self.isSyncedToAppleCalendar = isSyncedToAppleCalendar
    }
}
