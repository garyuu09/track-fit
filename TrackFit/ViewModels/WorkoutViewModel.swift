//
//  WorkoutViewModel.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/30.
//

import SwiftUI

@MainActor
class WorkoutViewModel: ObservableObject {
    /// 画面で入力するプロパティ
    @Published var exerciseName: String = ""
    @Published var weight: String = ""
    @Published var sets: Int = 1
    @Published var reps: Int = 10
    @Published var date: Date = Date()

    /// 作成 or 更新したイベントID（更新時に使う）
    @Published var eventId: String? = nil

    /// エラー/状態表示
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    /// Google Sign-In などで取得したアクセストークンを外部からセット
    var accessToken: String = ""

    /// 新規イベント作成
    func createEvent(dailyWorkout: DailyWorkout) async {
        do {
            isLoading = true
            errorMessage = nil

            let newId = try await GoogleCalendarAPI.createWorkoutEvent(accessToken: tempAccessToken, workout: dailyWorkout)

            self.eventId = newId

        } catch {
            self.errorMessage = error.localizedDescription
        }
        /// 新規イベント作成処理が終了したため、ローディング状態を解除する。
        isLoading = false
    }

    /// 既存イベントを更新
    func updateEvent() async {
        guard let eid = eventId else {
            self.errorMessage = "イベントIDが取得できません。"
            return
        }

        do {
            isLoading = true
            errorMessage = nil

            let workoutData = WorkoutEventData(exerciseName: exerciseName, weight: weight, sets: sets, reps: reps, date: date)

            try await GoogleCalendarAPI.updateWorkoutEvent(accessToken: accessToken, eventId: eid, workout: workoutData)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

}
