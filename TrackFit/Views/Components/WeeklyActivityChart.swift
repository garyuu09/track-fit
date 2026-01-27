//
//  WeeklyActivityChart.swift
//  TrackFit
//
//  Created by Ryuga on 2025/08/24.
//

import Charts
import SwiftUI

struct WeeklyActivityChart: View {
    let activity: [HomeViewModel.DailyActivity]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今週のアクティビティ")
                .font(.headline)

            Chart {
                ForEach(activity) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(
                        item.count > 0 ? Color.trackFitThemeColor : Color.gray.opacity(0.3))
                }
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }
}
