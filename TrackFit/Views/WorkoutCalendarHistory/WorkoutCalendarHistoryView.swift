import SwiftData
import SwiftUI

// MARK: - ワークアウトカレンダー履歴ビュー
struct WorkoutCalendarHistoryView: View {
    @Query(sort: \DailyWorkout.startDate, order: .forward) private var dailyWorkouts: [DailyWorkout]
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isCalendarFeatureEnabled") private var isCalendarFeatureEnabled: Bool = true

    @State private var currentMonth = Date()
    @State private var selectedDate: Date?
    @State private var selectedWorkout: DailyWorkout?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CalendarHistoryHeaderView(currentMonth: $currentMonth)

                CalendarWeekdayHeaderView()

                CalendarHistoryGridView(
                    currentMonth: currentMonth,
                    selectedDate: $selectedDate,
                    selectedWorkout: $selectedWorkout,
                    dailyWorkouts: dailyWorkouts
                )

                if let selectedWorkout = selectedWorkout {
                    SelectedWorkoutDetailView(
                        workout: selectedWorkout, isCalendarFeatureEnabled: isCalendarFeatureEnabled
                    )
                } else if let selectedDate = selectedDate {
                    VStack(spacing: 8) {
                        Text(DateHelper.formattedDate(selectedDate))
                            .font(.headline)
                        Text("この日はトレーニングがありません")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    Text("カレンダーから日付を選択してください")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("トレーニング履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WorkoutCalendarHistoryView()
}
