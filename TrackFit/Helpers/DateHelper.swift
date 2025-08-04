//
//  DateHelper.swift
//  TrackFit
//
//  Created by Claude on 2025/06/15.
//

import Foundation

/// 日付・時刻の表示フォーマットを統一するためのヘルパークラス
struct DateHelper {

    // MARK: - Private Properties (元の成功パターンに基づく実装)

    /// 日付のみ用フォーマッター（yyyy/MM/dd）- 日本語固定
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")  // 明示的にja_JPを指定
        formatter.dateFormat = "yyyy/MM/dd"  // 元の成功パターンと同じ
        return formatter
    }()

    /// 時刻のみ用フォーマッター（HH:mm）
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// 日付+時刻用フォーマッター（yyyy/MM/dd HH:mm）- 日本語固定
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")  // 明示的にja_JPを指定
        formatter.dateFormat = "yyyy/MM/dd HH:mm"  // 元の成功パターンと同じ
        return formatter
    }()

    // MARK: - Public Methods

    /// 日付のみをローカライズされた形式で表示
    /// - Parameter date: フォーマットする日付
    /// - Returns: フォーマットされた日付文字列（例: 2025/06/15）
    static func formattedDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    /// 時刻のみをローカライズされた形式で表示
    /// - Parameter date: フォーマットする日付
    /// - Returns: フォーマットされた時刻文字列（例: 15:45）
    static func formattedTime(_ date: Date) -> String {
        return timeFormatter.string(from: date)
    }

    /// 日付と時刻をローカライズされた形式で表示
    /// - Parameter date: フォーマットする日付
    /// - Returns: フォーマットされた日付時刻文字列（例: 2025/06/15 15:45）
    static func formattedDateTime(_ date: Date) -> String {
        return dateTimeFormatter.string(from: date)
    }

    /// トレーニング期間を表示用の文字列に変換
    /// - Parameters:
    ///   - startDate: 開始日時
    ///   - endDate: 終了日時
    /// - Returns: 期間表示文字列（例: "2025/06/15 15:00 - 16:30"）
    static func formattedWorkoutPeriod(startDate: Date, endDate: Date) -> String {
        let startDateString = formattedDate(startDate)
        let startTimeString = formattedTime(startDate)
        let endTimeString = formattedTime(endDate)

        // 同じ日の場合は日付を1回だけ表示
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return "\(startDateString) \(startTimeString) - \(endTimeString)"
        } else {
            // 異なる日の場合は両方の日付を表示
            let endDateString = formattedDate(endDate)
            return "\(startDateString) \(startTimeString) - \(endDateString) \(endTimeString)"
        }
    }

    /// Googleカレンダー用のISO8601フォーマット（APIとの通信用）
    /// - Parameter date: フォーマットする日付
    /// - Returns: ISO8601形式の文字列
    static func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)  // UTC
        return formatter.string(from: date)
    }

    /// デバッグ用：現在のロケール情報を取得
    static func debugLocaleInfo() -> String {
        let locale = Locale.current
        let testDate = Date()
        return """
            Current Locale:
            - identifier: \(locale.identifier)
            - languageCode: \(locale.languageCode ?? "nil")
            - Test date format: \(formattedDate(testDate))
            - Test datetime format: \(formattedDateTime(testDate))
            """
    }
}
