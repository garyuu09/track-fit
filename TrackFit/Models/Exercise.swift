//
//  Exercise.swift
//  TrackFit
//
//  Created by Ryuga on 2025/06/13.
//

import Foundation
import SwiftData

/// トレーニング種目のマスターデータを表すSwiftDataモデル
///
/// ユーザーが登録した種目（ベンチプレス、スクワットなど）を管理する。
/// カテゴリ（胸、脚など）でグループ化され、履歴画面での種目別表示に使用される。
@Model
class Exercise: Identifiable {
    var id = UUID()
    var name: String
    var category: String
    var memo: String
    var isRunning: Bool = false  // ランニング種目かどうか
    var createdAt: Date
    var updatedAt: Date

    init(name: String, category: String, memo: String = "", isRunning: Bool = false) {
        self.name = name
        self.category = category
        self.memo = memo
        self.isRunning = isRunning
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// 種目の情報を更新し、更新日時を記録する
    func updateExercise(name: String, category: String, memo: String, isRunning: Bool = false) {
        self.name = name
        self.category = category
        self.memo = memo
        self.isRunning = isRunning
        self.updatedAt = Date()
    }
}
