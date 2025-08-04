//
//  WorkoutRecord.swift
//  TrackFit
//
//  Created by Ryuga on 2025/03/22.
//

import Foundation
import SwiftData

// MARK: - 個別のトレーニング記録モデル
@Model
class WorkoutRecord: Identifiable {
    var id = UUID()
    var exerciseName: String
    var weight: Double
    var reps: Int
    var sets: Int

    init(exerciseName: String, weight: Double, reps: Int, sets: Int) {
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.sets = sets
    }
}
