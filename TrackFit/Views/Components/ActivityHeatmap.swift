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
                                    // 未来の日付や範囲外
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.gray.opacity(0.1))  // 透明ではなく、枠として薄く表示してもいいが、ここでは薄いグレー
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
        // ここでは単純に startDate から計算するのではなく、グリッドの左端を正確に合わせる必要がある
        // GitHubのように「一番左の列」は「3ヶ月前の日付が含まれる週」

        guard let startOfFirstWeek = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start
        else { return nil }

        // オフセット計算
        // weekIndex週目の、weekdayIndex日目 (0: Mon?)
        // CalendarのfirstWeekdayを考慮する必要があるが、ここではシンプルに加算

        // 日本のCalendarは日月火... (Sun=1)
        // weekdayIndex: 0-6 をどうマッピングするか
        // ここでは VStack 0 が一番上（月曜または日曜）。
        // UI的には月曜始まりが一般的。 0: Mon, 1: Tue...

        // startOfFirstWeekが日曜の場合、+1dが月曜。
        // 面倒なので、正確な日付計算を行う。

        let daysToAdd = (weekIndex * 7) + weekdayIndex
        // しかし、startOfFirstWeekのweekdayを知る必要がある。
        // startOfFirstWeekは常に日曜(1)だと仮定（日本のカレンダー）
        // 0番目のセルを日曜にするならそのまま。月曜にするならweekdayIndexとのズレを吸収。

        // ここでは、Visual重視で「とりあえず日付が連続していればOK」とするが、
        // ちゃんと日付と曜日を合わせる。

        return calendar.date(byAdding: .day, value: daysToAdd, to: startOfFirstWeek)
    }

    private func colorForActivity(date: Date) -> Color {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let count = activityLog[startOfDay, default: 0]

        // テーマカラー: TrackFitThemeColor (おそらく赤かオレンジ系?)
        // なければ青などで代用されるが、Assetにあるはず。

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
