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

    // ランニング判定フラグ
    var isRunning: Bool = false

    // 筋トレ用プロパティ
    var weight: Double?
    var reps: Int?
    var sets: Int?

    // ランニング用プロパティ
    var distance: Double?  // km
    var durationSeconds: Int?  // 秒

    // 筋トレ用イニシャライザ
    init(exerciseName: String, weight: Double, reps: Int, sets: Int) {
        self.exerciseName = exerciseName
        self.isRunning = false
        self.weight = weight
        self.reps = reps
        self.sets = sets
        self.distance = nil
        self.durationSeconds = nil
    }

    // ランニング用イニシャライザ
    init(exerciseName: String, distance: Double, durationSeconds: Int) {
        self.exerciseName = exerciseName
        self.isRunning = true
        self.weight = nil
        self.reps = nil
        self.sets = nil
        self.distance = distance
        self.durationSeconds = durationSeconds
    }

    // ペース計算（分/km）
    var paceString: String {
        guard let distance = distance, let duration = durationSeconds, distance > 0 else {
            return "--:--"
        }
        let paceSeconds = Double(duration) / distance
        let minutes = Int(paceSeconds) / 60
        let seconds = Int(paceSeconds) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    // 時間フォーマット
    var durationString: String {
        guard let duration = durationSeconds else { return "--:--:--" }
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
