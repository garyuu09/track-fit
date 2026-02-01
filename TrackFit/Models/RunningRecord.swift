//
//  RunningRecord.swift
//  TrackFit
//
//  Created by Gemini on 2026/02/01.
//

import Foundation
import SwiftData

// MARK: - ランニング記録
@Model
class RunningRecord: Identifiable {
    var id = UUID()
    var date: Date
    var distance: Double  // km
    var duration: TimeInterval  // 秒
    var runTypeRawValue: String  // RunType.rawValue
    var calories: Int?
    var averageHeartRate: Int?
    var memo: String?
    var createdAt: Date

    // Googleカレンダー連携
    var isSyncedToCalendar: Bool = false
    var eventId: String?

    // MARK: - Computed Properties

    /// ランニング種別
    var runType: RunType {
        get { RunType(rawValue: runTypeRawValue) ?? .jog }
        set { runTypeRawValue = newValue.rawValue }
    }

    /// ペース（分/km）- 例: 5.5 = 5分30秒/km
    var paceMinutesPerKm: Double {
        guard distance > 0 else { return 0 }
        return (duration / 60) / distance
    }

    /// ペース文字列（例: "5:30 /km"）
    var paceString: String {
        guard distance > 0 else { return "--:-- /km" }
        let totalSeconds = Int(duration / distance)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    /// 時間文字列（例: "1:30:00"）
    var durationString: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    // MARK: - Initializer

    init(
        date: Date,
        distance: Double,
        duration: TimeInterval,
        runType: RunType,
        calories: Int? = nil,
        averageHeartRate: Int? = nil,
        memo: String? = nil,
        isSyncedToCalendar: Bool = false,
        eventId: String? = nil
    ) {
        self.date = date
        self.distance = distance
        self.duration = duration
        self.runTypeRawValue = runType.rawValue
        self.calories = calories
        self.averageHeartRate = averageHeartRate
        self.memo = memo
        self.createdAt = Date()
        self.isSyncedToCalendar = isSyncedToCalendar
        self.eventId = eventId
    }
}
