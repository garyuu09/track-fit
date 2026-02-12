//
//  AppleCalendarError.swift
//  TrackFit
//

import Foundation

/// Appleカレンダー（EventKit）操作で発生するエラーを統一的に扱うエラー型
enum AppleCalendarError: LocalizedError {
    case accessDenied
    case calendarNotFound
    case eventNotFound
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "カレンダーへのアクセスが拒否されています。設定アプリから許可してください。"
        case .calendarNotFound:
            return "指定されたカレンダーが見つかりません。"
        case .eventNotFound:
            return "更新対象のイベントが見つかりません。"
        case .saveFailed(let underlying):
            return "イベントの保存に失敗しました: \(underlying.localizedDescription)"
        }
    }
}
