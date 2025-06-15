//
//  WorkoutCalendarHistoryView.swift
//  TrackFit
//
//  Created by Claude on 2025/06/15.
//

import SwiftData
import SwiftUI

// MARK: - ワークアウトカレンダー履歴ビュー
struct WorkoutCalendarHistoryView: View {
    @Query(sort: \DailyWorkout.startDate, order: .forward) private var dailyWorkouts: [DailyWorkout]
    @Environment(\.dismiss) private var dismiss

    @State private var currentMonth = Date()
    @State private var selectedDate: Date?
    @State private var selectedWorkout: DailyWorkout?

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // カレンダーヘッダー
                CalendarHistoryHeaderView(currentMonth: $currentMonth)

                // 曜日ヘッダー
                CalendarWeekdayHeaderView()

                // カレンダーグリッド
                CalendarHistoryGridView(
                    currentMonth: currentMonth,
                    selectedDate: $selectedDate,
                    selectedWorkout: $selectedWorkout,
                    dailyWorkouts: dailyWorkouts
                )

                // 選択した日のワークアウト詳細
                if let selectedWorkout = selectedWorkout {
                    SelectedWorkoutDetailView(workout: selectedWorkout)
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

// MARK: - カレンダーヘッダー
struct CalendarHistoryHeaderView: View {
    @Binding var currentMonth: Date
    private let calendar = Calendar.current

    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }

            Spacer()

            Text(monthYearString)
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }

    private func previousMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else {
            return
        }
        currentMonth = newMonth
    }

    private func nextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else {
            return
        }
        // 未来の月は表示しない
        if newMonth <= Date() {
            currentMonth = newMonth
        }
    }
}

// MARK: - 曜日ヘッダー
struct CalendarWeekdayHeaderView: View {
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - カレンダーグリッド
struct CalendarHistoryGridView: View {
    let currentMonth: Date
    @Binding var selectedDate: Date?
    @Binding var selectedWorkout: DailyWorkout?
    let dailyWorkouts: [DailyWorkout]

    private let calendar = Calendar.current

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
            ForEach(monthDates, id: \.self) { date in
                CalendarHistoryDateCell(
                    date: date,
                    isSelected: selectedDate != nil
                        && calendar.isDate(date, inSameDayAs: selectedDate!),
                    isCurrentMonth: calendar.isDate(
                        date, equalTo: currentMonth, toGranularity: .month),
                    hasWorkout: hasWorkout(on: date),
                    workoutCount: workouts(for: date).count,
                    isToday: calendar.isDateInToday(date)
                ) {
                    handleDateTap(date: date)
                }
            }
        }
        .padding(.horizontal)
    }

    private var monthDates: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }

        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        let startDate =
            calendar.date(byAdding: .day, value: -(firstWeekday - 1), to: firstOfMonth)
            ?? firstOfMonth

        var dates: [Date] = []
        for i in 0..<42 {  // 6週間分
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                dates.append(date)
            }
        }

        return dates
    }

    private func hasWorkout(on date: Date) -> Bool {
        dailyWorkouts.contains { workout in
            calendar.isDate(workout.startDate, inSameDayAs: date)
        }
    }

    private func workouts(for date: Date) -> [DailyWorkout] {
        return dailyWorkouts.filter { workout in
            calendar.isDate(workout.startDate, inSameDayAs: date)
        }
    }

    private func handleDateTap(date: Date) {
        selectedDate = date
        let workoutsForDate = workouts(for: date)
        selectedWorkout = workoutsForDate.first
    }
}

// MARK: - カレンダー日付セル
struct CalendarHistoryDateCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasWorkout: Bool
    let workoutCount: Int
    let isToday: Bool
    let action: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)

                if hasWorkout {
                    Circle()
                        .fill(isSelected ? Color.white : Color.blue)
                        .frame(width: 6, height: 6)
                } else {
                    Spacer()
                        .frame(height: 6)
                }
            }
            .frame(width: 40, height: 40)
            .background(backgroundColor)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else if !isCurrentMonth {
            return .secondary
        } else {
            return .primary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue.opacity(0.1)
        } else {
            return .clear
        }
    }

    private var borderColor: Color {
        if isToday && !isSelected {
            return .blue
        } else {
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        isToday && !isSelected ? 1 : 0
    }
}

// MARK: - 選択されたワークアウト詳細
struct SelectedWorkoutDetailView: View {
    let workout: DailyWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(DateHelper.formattedDate(workout.startDate))
                    .font(.headline)

                Spacer()

                if workout.isSyncedToCalendar {
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
                            Text("\(Int(record.weight))kg × \(record.reps)回 × \(record.sets)セット")
                                .font(.caption)
                                .foregroundColor(.secondary)
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

#Preview {
    WorkoutCalendarHistoryView()
}
