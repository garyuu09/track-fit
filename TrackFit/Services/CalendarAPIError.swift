//
//  CalendarAPIError.swift
//  TrackFit
//
//  Refactored from GoogleCalendarAPI.swift
//

import Foundation

/// Google Calendar API通信で発生するエラーを統一的に扱うエラー型
enum CalendarAPIError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, body: String)
    case tokenNotFound
    case tokenExpired
    case refreshFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .httpError(let statusCode, let body):
            return "APIエラー (\(statusCode))\n\(body)"
        case .tokenNotFound:
            return "アクセストークンが見つかりません"
        case .tokenExpired:
            return "アクセストークンの期限が切れています"
        case .refreshFailed(let underlying):
            return "トークン更新に失敗しました: \(underlying.localizedDescription)"
        }
    }
}
