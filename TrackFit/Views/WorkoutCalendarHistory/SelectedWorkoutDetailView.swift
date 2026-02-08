import SwiftUI

// MARK: - 選択されたワークアウト詳細
struct SelectedWorkoutDetailView: View {
    let workout: DailyWorkout
    let isCalendarFeatureEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(DateHelper.formattedDate(workout.startDate))
                    .font(.headline)

                Spacer()

                if isCalendarFeatureEnabled && workout.isSyncedToCalendar {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.checkmark")
                        Text("連携済み")
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("トレーニング内容")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if workout.records.isEmpty {
                    Text("記録なし")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(workout.records) { record in
                        HStack {
                            Text(record.exerciseName)
                                .font(.caption)
                            Spacer()
                            if record.isRunning {
                                Text(
                                    "\(record.distance ?? 0, specifier: "%.2f")km - \(record.durationString)"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            } else {
                                Text(
                                    "\(record.weight ?? 0, specifier: "%.1f")kg × \(record.reps ?? 0)回 × \(record.sets ?? 0)セット"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
