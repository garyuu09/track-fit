//
//  WorkoutRecord.swift
//  TrackFit
//
//  Created by Ryuga on 2025/03/22.
//

import Foundation

// MARK: - 個別のトレーニング記録モデル
struct WorkoutRecord: Identifiable {
  let id = UUID()
  var exerciseName: String
  var weight: Double
  var reps: Int
  var sets: Int
}
