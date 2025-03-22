//
//  DailyWorkout.swift
//  TrackFit
//
//  Created by Ryuga on 2025/03/22.
//

import Foundation

// MARK: - 1日分のトレーニング記録
struct DailyWorkout: Identifiable {
  let id = UUID()
  var startDate: Date
  var endDate: Date

  // その日実施したトレーニング一覧
  var records: [WorkoutRecord]

  // Googleカレンダー連携済みかどうか
  var isSyncedToCalendar: Bool = false
}
