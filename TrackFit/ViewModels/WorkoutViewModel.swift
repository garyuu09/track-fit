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

    /// カレンダーイベントの色設定を@AppStorageから取得
    @AppStorage("calendarEventColor") private var calendarEventColor: CalendarEventColor = .みかん

    /// 新規イベント作成
    func createEvent(dailyWorkout: DailyWorkout) async -> Bool {
        do {
            isLoading = true
            errorMessage = nil

            let accessToken = UserDefaults.standard.string(forKey: "GoogleAccessToken") ?? ""
            let newId = try await GoogleCalendarAPI.createWorkoutEvent(
                accessToken: accessToken,
                workout: dailyWorkout,
                colorId: calendarEventColor.rawValue)

            self.eventId = newId

        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
        /// 新規イベント作成処理が終了したため、ローディング状態を解除する。
        isLoading = false
        return true
    }

    /// 既存イベントを更新
    func updateEvent(dailyWorkout: DailyWorkout) async -> Bool {
        guard let eid = dailyWorkout.eventId else {
            self.errorMessage = "イベントIDが取得できません。"
            return false
        }

        do {
            let accessToken = UserDefaults.standard.string(forKey: "GoogleAccessToken") ?? ""
            isLoading = true
            errorMessage = nil

            try await GoogleCalendarAPI.updateWorkoutEvent(
                accessToken: accessToken,
                eventId: eid,
                workout: dailyWorkout,
                colorId: calendarEventColor.rawValue)

            isLoading = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
