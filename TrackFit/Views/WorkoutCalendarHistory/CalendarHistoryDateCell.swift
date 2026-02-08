import SwiftUI

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
                        .fill(isSelected ? Color.white : Color.accentColor)
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
            return .accentColor
        } else if !isCurrentMonth {
            return .secondary
        } else {
            return .primary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return .accentColor
        } else if isToday {
            return .accentColor.opacity(0.1)
        } else {
            return .clear
        }
    }

    private var borderColor: Color {
        if isToday && !isSelected {
            return .accentColor
        } else {
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        isToday && !isSelected ? 1 : 0
    }
}
