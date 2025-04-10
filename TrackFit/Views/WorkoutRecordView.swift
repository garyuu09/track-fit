import SwiftData
import SwiftUI

// MARK: - メインビュー
struct WorkoutRecordView: View {
    @Query private var dailyWorkouts: [DailyWorkout] = []

    @State private var searchText: String = ""
    // シートの表示・非表示を管理するフラグ
    @State private var showDatePickerSheet = false
    @State var showDatePicker: Bool = false
    @State var savedDate: Date? = nil

    @Environment(\.modelContext) private var context
    // 選択した日付
    @State private var selectedDate = Date()

    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    ForEach(dailyWorkouts) { daily in
                        VStack(alignment: .leading, spacing: 8) {
                            // 上段: 三角アイコン + 日付 + Googleカレンダー反映ボタン
                            HStack {
                                NavigationLink {
                                    // 遷移先 (WorkoutSheetView) にバインディングでDailyWorkoutを渡す
                                    WorkoutSheetView(daily: daily)
                                } label: {
                                    // 日付テキスト
                                    Text(formattedDate(date: daily.startDate))
                                        .font(.headline)

                                    Spacer()

                                    // Googleカレンダー連携ボタン
                                    Button(action: {
                                        daily.isSyncedToCalendar.toggle()
                                    }) {
                                        if daily.isSyncedToCalendar {
                                            // 連携済み
                                            Label("連携済み", systemImage: "calendar.badge.checkmark")
                                                .font(.footnote)
                                                .foregroundColor(.green)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.green, lineWidth: 1)
                                                )
                                        } else {
                                            // 未連携
                                            Label("連携", systemImage: "calendar.badge.plus")
                                                .font(.footnote)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.blue, lineWidth: 1)
                                                )
                                        }
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            // Grid全体で左寄せ
                            Grid(alignment: .leading) {
                                // レコードごとに行を作成
                                ForEach(daily.records) { record in
                                    GridRow {
                                        Text(record.exerciseName)
                                        Text("\(Int(record.weight))kg")
                                        Text("x")
                                        Text("\(record.reps)回")
                                        Text("x")
                                        Text("\(record.sets)セット")
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .navigationTitle("トレーニング一覧")
                .navigationBarTitleDisplayMode(.inline)
                // 丸い追加ボタン（下部固定）
                .safeAreaInset(edge: .bottom, alignment: .center) {
                    Button(action: {
                        // シートを表示させる
                        showDatePicker = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)

                            Text("トレーニング日を追加")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .shadow(
                            color: Color.black.opacity(0.2),
                            radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .zIndex(1)
                }
                .overlay {
                    if dailyWorkouts.isEmpty {
                        /// はじめての利用（まだ一度も記録がない場合）
                        ContentUnavailableView(
                            "トレーニング記録がありません",
                            systemImage: "figure.run",
                            description: Text("初めてのトレーニングを記録してみましょう！")
                        )
                    }
                }
                // シートを表示するためのモディファイア
                .sheet(isPresented: $showDatePickerSheet) {
                    // シートの中身
                    VStack(spacing: 20) {
                        Text("トレーニング日を選択してください")
                            .font(.headline)

                        // 日付の選択を行うDatePicker
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)

                        Button("完了") {
                            // シートを閉じる
                            showDatePickerSheet = false
                        }
                    }
                    .presentationDetents([
                        .height(300),
                        .fraction(0.3),
                    ])
                    .padding()
                }
            }
            if showDatePicker {
                CustomDatePicker(
                    context: context,
                    showDatePicker: $showDatePicker,
                    savedDate: $savedDate,
                    dailyWorkouts: dailyWorkouts,
                    selectedDate: savedDate ?? Date()
                )
                .animation(.linear, value: savedDate)
                .transition(.opacity)
            }
        }
    }

    /// Date を "yyyy/MM/dd" 形式の文字列に変換する関数
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)  // 西暦を使う
        formatter.locale = Locale(identifier: "ja_JP")  // 日本語ロケール
        formatter.dateFormat = "yyyy/MM/dd"  // 表示形式
        return formatter.string(from: date)
    }
}

struct CustomDatePicker: View {
    @Environment(\.colorScheme) var colorScheme

    var context: ModelContext
    @Binding var showDatePicker: Bool
    @Binding var savedDate: Date?
    var dailyWorkouts: [DailyWorkout]
    @State var selectedDate: Date = Date()

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
                        showDatePicker = false
                        // 新規の日付を追加するなどの処理 (例)
                        let newDaily = DailyWorkout(
                            startDate: savedDate, endDate: savedDate.addingTimeInterval(60 * 60),
                            records: [], isSyncedToCalendar: true)
                        context.insert(newDaily)
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
        }
    }
}

// MARK: - ヘルパー
private func dateFromString(_ string: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter.date(from: string) ?? Date()
}

// MARK: - プレビュー
#Preview {
    WorkoutRecordView()
}
