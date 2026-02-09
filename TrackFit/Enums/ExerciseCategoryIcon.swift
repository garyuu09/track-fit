//
//  ExerciseCategoryIcon.swift
//  TrackFit
//

import SwiftUI

/// トレーニングカテゴリに対応するSF Symbolsアイコンと色を提供するヘルパー
///
/// 定義済みの8カテゴリに対してアイコンと色をマッピングし、
/// 未定義のカスタムカテゴリにはデフォルトのアイコン・色を返す。
enum ExerciseCategoryIcon {

    /// カテゴリ名に対応するSF Symbolsアイコン名を返す
    static func icon(for category: String) -> String {
        switch category {
        case "胸": return "figure.strengthtraining.traditional"
        case "背中": return "figure.rower"
        case "肩": return "figure.boxing"
        case "腕": return "dumbbell.fill"
        case "脚": return "figure.step.training"
        case "腹筋": return "figure.core.training"
        case "有酸素": return "heart.circle.fill"
        case "その他": return "ellipsis.circle.fill"
        default: return "figure.mixed.cardio"
        }
    }

    /// カテゴリ名に対応するテーマカラーを返す
    static func color(for category: String) -> Color {
        switch category {
        case "胸": return .red
        case "背中": return .blue
        case "肩": return .orange
        case "腕": return .purple
        case "脚": return .green
        case "腹筋": return .yellow
        case "有酸素": return .pink
        case "その他": return .gray
        default: return .secondary
        }
    }
}
