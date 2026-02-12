//
//  RunningViewModel.swift
//  TrackFit
//
//  Created by Gemini on 2026/02/01.
//

import Foundation
import SwiftData
import SwiftUI

/// ランニング記録の入力フォームを管理するViewModel
///
/// 距離・時間・ランニング種別の入力状態を保持し、`RunningRecord`の保存・更新・編集を行う。
/// ペース計算やバリデーション機能も提供する。
// MARK: - ランニング記録ViewModel
@MainActor
class RunningViewModel: ObservableObject {

    // MARK: - 入力フォーム用プロパティ
    @Published var selectedDate: Date = Date()
    @Published var distance: Double = 0.0
    @Published var hours: Int = 0
    @Published var minutes: Int = 0
    @Published var seconds: Int = 0
    @Published var selectedRunType: RunType = .jog
    @Published var memo: String = ""

    // MARK: - Computed Properties

    /// 合計時間（秒）
    var totalDuration: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }

    /// ペース文字列
    var paceString: String {
        guard distance > 0, totalDuration > 0 else { return "--:-- /km" }
        let totalSeconds = Int(totalDuration / distance)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d /km", mins, secs)
    }

    /// 入力が有効かどうか
    var isValidInput: Bool {
        distance > 0 && totalDuration > 0
    }

    // MARK: - Methods

    /// ランニング記録を保存し、作成したレコードを返す
    @discardableResult
    func saveRunningRecord(context: ModelContext) -> RunningRecord {
        let record = RunningRecord(
            date: selectedDate,
            distance: distance,
            duration: totalDuration,
            runType: selectedRunType,
            memo: memo.isEmpty ? nil : memo
        )
        context.insert(record)
        resetForm()
        return record
    }

    /// フォームをリセット
    func resetForm() {
        selectedDate = Date()
        distance = 0.0
        hours = 0
        minutes = 0
        seconds = 0
        selectedRunType = .jog
        memo = ""
    }

    /// 編集用に値を設定
    func loadForEdit(record: RunningRecord) {
        selectedDate = record.date
        distance = record.distance

        let totalSeconds = Int(record.duration)
        hours = totalSeconds / 3600
        minutes = (totalSeconds % 3600) / 60
        seconds = totalSeconds % 60

        selectedRunType = record.runType
        memo = record.memo ?? ""
    }

    /// 既存のレコードを更新
    func updateRunningRecord(_ record: RunningRecord) {
        record.date = selectedDate
        record.distance = distance
        record.duration = totalDuration
        record.runType = selectedRunType
        record.memo = memo.isEmpty ? nil : memo
    }
}
