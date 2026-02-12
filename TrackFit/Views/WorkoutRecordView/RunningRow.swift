//
//  RunningRow.swift
//  TrackFit
//
//  Created by Gemini on 2026/02/01.
//

import SwiftUI

// MARK: - ランニング記録行コンポーネント
struct RunningRow: View {
    let record: RunningRecord
    let isCalendarFeatureEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - ヘッダー行
            HStack {
                Text(DateHelper.formattedDate(record.date))
                    .font(.headline)

                Spacer()

                // カレンダー同期状態
                if isCalendarFeatureEnabled {
                    if record.isSyncedToCalendar || record.isSyncedToAppleCalendar {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.checkmark")
                            Text("連携済み")
                        }
                        .font(.footnote)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, lineWidth: 1)
                        )
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.exclamationmark")
                            Text("未連携")
                        }
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: 1)
                        )
                    }
                }
            }

            // MARK: - ランニング種別タグ
            HStack(spacing: 6) {
                Image(systemName: record.runType.icon)
                    .foregroundColor(record.runType.color)
                Text(record.runType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(record.runType.color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(record.runType.color.opacity(0.1))
            .cornerRadius(8)

            // MARK: - 記録詳細
            HStack(spacing: 16) {
                // 距離
                VStack(alignment: .leading, spacing: 2) {
                    Text("距離")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f km", record.distance))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Divider()
                    .frame(height: 30)

                // 時間
                VStack(alignment: .leading, spacing: 2) {
                    Text("時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(record.durationString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Divider()
                    .frame(height: 30)

                // ペース
                VStack(alignment: .leading, spacing: 2) {
                    Text("ペース")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(record.paceString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // MARK: - メモ（存在する場合）
            if let memo = record.memo, !memo.isEmpty {
                Text(memo)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
    }
}
