import SwiftData
import SwiftUI

struct CustomDatePicker: View {
    @Environment(\.colorScheme) var colorScheme

    var context: ModelContext
    @Binding var showDatePicker: Bool
    @Binding var savedDate: Date?
    var dailyWorkouts: [DailyWorkout]
    @State var selectedDate: Date = Date()
    @State private var showSaveErrorAlert = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showDatePicker = false
                }
            VStack {
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .environment(\.calendar, Calendar(identifier: .gregorian))
                .datePickerStyle(.graphical)
                Divider()
                HStack {
                    Button("キャンセル") {
                        showDatePicker = false
                    }
                    Spacer()
                    Button("保存") {
                        savedDate = selectedDate
                        guard let savedDate else { return }
                        let newDaily = DailyWorkout(
                            startDate: savedDate, endDate: savedDate.addingTimeInterval(60 * 60),
                            records: [], isSyncedToCalendar: false)
                        context.insert(newDaily)
                        do {
                            try context.save()
                            showDatePicker = false
                        } catch {
                            #if DEBUG
                                print("データ保存エラー: \(error.localizedDescription)")
                            #endif
                            showSaveErrorAlert = true
                        }
                    }
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 10)
            }
            .padding(.horizontal, 20)
            .background(
                colorScheme == .dark ? Color.black.cornerRadius(30) : Color.white.cornerRadius(30)
            )
            .padding(.horizontal, 20)
            .alert("データの保存に失敗しました", isPresented: $showSaveErrorAlert) {
                Button("閉じる", role: .cancel) {}
            } message: {
                Text("もう一度お試しください。")
            }
        }
    }
}
