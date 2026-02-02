//
//  Exercise.swift
//  TrackFit
//
//  Created by Ryuga on 2025/06/13.
//

import Foundation
import SwiftData

// MARK: - トレーニング種目モデル
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

    func updateExercise(name: String, category: String, memo: String, isRunning: Bool = false) {
        self.name = name
        self.category = category
        self.memo = memo
        self.isRunning = isRunning
        self.updatedAt = Date()
    }
}
