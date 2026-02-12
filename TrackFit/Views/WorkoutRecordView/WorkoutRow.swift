import SwiftUI

struct WorkoutRow: View {
    let daily: DailyWorkout
    let isSyncing: Bool
    @Binding var showSyncErrorAlert: Bool
    let isCalendarFeatureEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(DateHelper.formattedDate(daily.startDate))
                    .font(.headline)

                Spacer()

                // カレンダー機能が有効な場合のみ同期状態を表示
                if isCalendarFeatureEnabled {
                    if isSyncing {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("連携中…")
                        }
                        .font(.footnote)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    } else if daily.isSyncedToCalendar || daily.isSyncedToAppleCalendar {
                        HStack(spacing: 15) {
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
                        HStack(spacing: 15) {
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

            Grid(alignment: .leading) {
                ForEach(daily.records) { record in
                    GridRow {
                        Text(record.exerciseName)
                        if record.isRunning {
                            Text("\(record.distance ?? 0, specifier: "%.2f")km")
                            Text("-")
                            Text(record.durationString)
                            Text("")
                            Text(record.paceString)
                        } else {
                            Text("\(record.weight ?? 0, specifier: "%.1f")kg")
                            Text("x")
                            Text("\(record.reps ?? 0)回")
                            Text("x")
                            Text("\(record.sets ?? 0)セット")
                        }
                    }
                    .font(.caption)
                }
            }
        }
    }
}
