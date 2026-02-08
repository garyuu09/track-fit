import SwiftUI

// MARK: - カレンダーヘッダー
struct CalendarHistoryHeaderView: View {
    @Binding var currentMonth: Date
    private let calendar = Calendar.current

    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }

            Spacer()

            Text(monthYearString)
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.accentColor)
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
