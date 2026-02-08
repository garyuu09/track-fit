//
//  HomeViewModel.swift
//  TrackFit
//
//  Created by Ryuga on 2025/08/24.
//

import Foundation
import SwiftData

/// ホーム画面の状態管理を担当するViewModel
///
/// 直近のトレーニング記録、週間ストリーク、アクティビティヒートマップ用データを提供する。
/// 筋トレ（`DailyWorkout`）とランニング（`RunningRecord`）の両方を統合して集計する。
@MainActor
class HomeViewModel: ObservableObject {
    @Published var currentWeekStreak: Int = 0
    @Published var recentWorkouts: [DailyWorkout] = []

    // 週間アクティビティ (月〜日、7日分)
    struct DailyActivity: Identifiable {
        let id = UUID()
        let label: String  // 曜日ラベル (Mon, Tue...)
        let count: Int  // アクティビティ回数
    }

    // ヒートマップ用データ (日付 -> 回数)
    @Published var activityLog: [Date: Int] = [:]

    func updateStats(workouts: [DailyWorkout], runningRecords: [RunningRecord] = []) {
        self.recentWorkouts = Array(workouts.sorted(by: { $0.startDate > $1.startDate }).prefix(5))
        self.currentWeekStreak = calculateStreak(workouts: workouts, runningRecords: runningRecords)

        self.activityLog = calculateActivityLog(workouts: workouts, runningRecords: runningRecords)
    }

    private func calculateStreak(
        workouts: [DailyWorkout], runningRecords: [RunningRecord] = []
    ) -> Int {
        guard !workouts.isEmpty || !runningRecords.isEmpty else { return 0 }

        var streak = 0
        let calendar = Calendar.current

        var workoutWeeks = Set<DateComponent>()  // yearForWeekOfYear, weekOfYear

        for workout in workouts {
            let components = calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: workout.startDate)
            workoutWeeks.insert(components)
        }

        for record in runningRecords {
            let components = calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: record.date)
            workoutWeeks.insert(components)
        }

        // 今週の確認
        let todayComponents = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: Date())
        var currentComponents = todayComponents

        // 今週の記録がなくても先週まではストリーク継続とみなす
        if !workoutWeeks.contains(currentComponents) {
            // 今週ないので先週をチェック
            if let lastWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) {
                currentComponents = calendar.dateComponents(
                    [.yearForWeekOfYear, .weekOfYear], from: lastWeekDate)
                if !workoutWeeks.contains(currentComponents) {
                    return 0
                }
            } else {
                return 0
            }
        }

        // 遡ってカウント
        while workoutWeeks.contains(currentComponents) {
            streak += 1
            if let date = calendar.date(from: currentComponents),
                let prevWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: date)
            {
                currentComponents = calendar.dateComponents(
                    [.yearForWeekOfYear, .weekOfYear], from: prevWeekDate)
            } else {
                break
            }
        }

        return streak
    }

    private func calculateActivityLog(
        workouts: [DailyWorkout], runningRecords: [RunningRecord] = []
    ) -> [Date: Int] {
        let calendar = Calendar.current
        var log: [Date: Int] = [:]

        for workout in workouts {
            // 時間情報を切り捨てて日付のみにする
            let date = calendar.startOfDay(for: workout.startDate)
            log[date, default: 0] += 1
        }

        for record in runningRecords {
            let date = calendar.startOfDay(for: record.date)
            log[date, default: 0] += 1
        }
        return log
    }
}

// DateComponentをSetで使えるようにHashable準拠（標準で準拠しているはずだが明示的に使うためのエイリアス）
typealias DateComponent = DateComponents

extension Date {
    var startOfWeek: Date {
        let calendar = Calendar.current
        return calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
    }
}
