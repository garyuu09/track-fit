//
//  ActivityHeatmap.swift
//  TrackFit
//
//  Created by Ryuga on 2025/08/24.
//

import SwiftUI

struct ActivityHeatmap: View {
    let activityLog: [Date: Int]

    // 表示する日数（過去3ヶ月分くらい）
    let daysToShow = 90

    // カレンダー風: 7行 (Mon-Sun)
    // 週の数
    private var weeksCount: Int {
        (daysToShow / 7) + 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("アクティビティログ")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                // GitHub風: 左から右へ時間が進む
                HStack(spacing: 4) {
                    ForEach(0..<weeksCount, id: \.self) { weekIndex in
                        VStack(spacing: 4) {
                            ForEach(0..<7, id: \.self) { weekdayIndex in
                                let date = dateFor(weekIndex: weekIndex, weekdayIndex: weekdayIndex)
                                if let date = date, date <= Date() {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(colorForActivity(date: date))
                                        .frame(width: 12, height: 12)
                                } else {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private var endDate: Date {
        Date()
    }

    private var startDate: Date {
        Calendar.current.date(byAdding: .day, value: -daysToShow, to: endDate)!
    }

    private func dateFor(weekIndex: Int, weekdayIndex: Int) -> Date? {
        let calendar = Calendar.current
        // startDateが含まれる週の始まりを取得 (月曜始まりと仮定)
        guard let startOfFirstWeek = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start
        else { return nil }

        let daysToAdd = (weekIndex * 7) + weekdayIndex
        return calendar.date(byAdding: .day, value: daysToAdd, to: startOfFirstWeek)
    }

    private func colorForActivity(date: Date) -> Color {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let count = activityLog[startOfDay, default: 0]

        if count == 0 {
            return Color.gray.opacity(0.2)
        } else if count == 1 {
            return Color.trackFitThemeColor.opacity(0.4)
        } else if count == 2 {
            return Color.trackFitThemeColor.opacity(0.7)
        } else {
            return Color.trackFitThemeColor
        }
    }
}
