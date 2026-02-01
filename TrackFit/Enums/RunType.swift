//
//  RunType.swift
//  TrackFit
//
//  Created by Gemini on 2026/02/01.
//

import Foundation
import SwiftUI

// MARK: - ランニング種別
enum RunType: String, CaseIterable, Codable, Identifiable {
    case jog = "ジョグ"
    case tempo = "テンポ走"
    case interval = "インターバル"
    case longRun = "ロング走"
    case recovery = "リカバリー"
    case race = "レース"

    var id: String { rawValue }

    /// アイコン
    var icon: String {
        switch self {
        case .jog: return "figure.walk"
        case .tempo: return "speedometer"
        case .interval: return "timer"
        case .longRun: return "figure.run"
        case .recovery: return "heart"
        case .race: return "flag.checkered"
        }
    }

    /// 色
    var color: Color {
        switch self {
        case .jog: return .green
        case .tempo: return .orange
        case .interval: return .red
        case .longRun: return .blue
        case .recovery: return .mint
        case .race: return .purple
        }
    }
}
