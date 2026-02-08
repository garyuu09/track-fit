import SwiftUI

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
        for i in 0..<42 {
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
