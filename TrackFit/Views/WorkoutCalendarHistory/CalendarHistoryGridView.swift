import SwiftUI

// MARK: - カレンダーグリッド
struct CalendarHistoryGridView: View {
    let currentMonth: Date
    @Binding var selectedDate: Date?
    @Binding var selectedWorkout: DailyWorkout?
    let dailyWorkouts: [DailyWorkout]

    private let calendar = Calendar.current

    private var workoutsByDay: [Date: [DailyWorkout]] {
        Dictionary(grouping: dailyWorkouts) { workout in
            calendar.startOfDay(for: workout.startDate)
        }
    }

    var body: some View {
        let groupedWorkouts = workoutsByDay
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
            ForEach(monthDates, id: \.self) { date in
                let dayWorkouts = groupedWorkouts[calendar.startOfDay(for: date)]
                CalendarHistoryDateCell(
                    date: date,
                    isSelected: selectedDate != nil
                        && calendar.isDate(date, inSameDayAs: selectedDate!),
                    isCurrentMonth: calendar.isDate(
                        date, equalTo: currentMonth, toGranularity: .month),
                    hasWorkout: dayWorkouts != nil,
                    workoutCount: dayWorkouts?.count ?? 0,
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

    private func handleDateTap(date: Date) {
        selectedDate = date
        selectedWorkout = workoutsByDay[calendar.startOfDay(for: date)]?.first
    }
}
