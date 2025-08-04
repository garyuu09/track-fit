//
//  DailyWorkout.swift
//  TrackFit
//
//  Created by Ryuga on 2025/03/22.
//

import Foundation
import SwiftData

// MARK: - 1日分のトレーニング記録
@Model
class DailyWorkout: Identifiable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var eventId: String?

    // その日実施したトレーニング一覧
    var records: [WorkoutRecord]

    // Googleカレンダー連携済みかどうか
    var isSyncedToCalendar: Bool = false

    init(
        startDate: Date, endDate: Date, records: [WorkoutRecord], eventId: String? = nil,
        isSyncedToCalendar: Bool
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.records = records
        self.eventId = eventId
        self.isSyncedToCalendar = isSyncedToCalendar
    }
}
