import SwiftData
import SwiftUI

// MARK: - メインビュー
struct WorkoutRecordView: View {
    enum FilterType: String, CaseIterable, Identifiable {
        case all, thisWeek, thisMonth, custom
        var id: String { self.rawValue }
    }

    // 「連携画面を見たか？」のフラグを永続化
    @AppStorage("hasShownCalendarIntegration") private var hasShownCalendarIntegration: Bool = false
    // Googleカレンダー連携状態
    @AppStorage("isCalendarLinked") private var isCalendarLinked: Bool = false
    // バナー表示フラグ
    @State private var showIntegrationBanner: Bool = true
    // 同期失敗アラート用フラグ
    @State private var showSyncErrorAlert: Bool = false
    // モーダル表示フラグ
    @State private var isShowCalendarIntegration: Bool = false

    @Query private var dailyWorkouts: [DailyWorkout] = []
    // シートの表示・非表示を管理するフラグ
    @State private var showDatePickerSheet = false
    @State var showDatePicker: Bool = false
    @State var savedDate: Date? = nil
    @State private var showCustomDateSheet = false

    @Environment(\.modelContext) private var context
    // 選択した日付
    @State private var selectedDate = Date()
    @State private var selectedFilter: FilterType = .all
    @State private var customStartDate: Date = {
        let now = Date()
        return Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
    }()
    @State private var customEndDate: Date = Date()
    @State private var customTabSelection: Int = 0

    private var filteredWorkouts: [DailyWorkout] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedFilter {
        case .all:
            return dailyWorkouts
        case .thisWeek:
            guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
                return dailyWorkouts
            }
            return dailyWorkouts.filter { $0.startDate >= startOfWeek && $0.startDate <= now }
        case .thisMonth:
            guard let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start else {
                return dailyWorkouts
            }
            return dailyWorkouts.filter { $0.startDate >= startOfMonth && $0.startDate <= now }
        case .custom:
            return dailyWorkouts.filter {
                $0.startDate >= customStartDate && $0.startDate <= customEndDate
            }
        }
    }

    private var dateRangeLabel: String {
        switch selectedFilter {
        case .all:
            return "すべての記録"
        case .thisWeek:
            return "今週の記録"
        case .thisMonth:
            return "今月の記録"
        case .custom:
            return
                "\(formattedDate(date: customStartDate)) 〜 \(formattedDate(date: customEndDate)) の記録"
        }
    }

    var body: some View {
        ZStack {
            NavigationStack {
                Picker("期間フィルター", selection: $selectedFilter) {
                    Text("全て").tag(FilterType.all)
                    Text("今週").tag(FilterType.thisWeek)
                    Text("今月").tag(FilterType.thisMonth)
                    Text("カスタム").tag(FilterType.custom)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Googleカレンダー未連携バナー
                if !isCalendarLinked && hasShownCalendarIntegration && showIntegrationBanner {
                    AlertBannerView(
                        isShowCalendarIntegration: $isShowCalendarIntegration,
                        showIntegrationBanner: $showIntegrationBanner)
                }

                List {
                    Section(
                        header:
                            HStack {
                                if selectedFilter == .custom {
                                    Button(action: {
                                        showCustomDateSheet = true
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "calendar")
                                            Text(dateRangeLabel)
                                                .underline()
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                } else {
                                    Text(dateRangeLabel)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                    ) {
                        ForEach(filteredWorkouts) { daily in
                            NavigationLink(destination: WorkoutSheetView(daily: daily)) {
                                WorkoutRow(daily: daily)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            }

                        }
                        .onDelete(perform: deleteDailyWorkout)
                    }
                }
                .navigationTitle("トレーニング一覧")
                .toolbar {
                    EditButton()
                }
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
                .sheet(isPresented: $showCustomDateSheet) {
                    NavigationStack {
                        VStack(spacing: 16) {
                            // タブ切り替えセグメント
                            Picker("", selection: $customTabSelection) {
                                Text("開始日").tag(0)
                                Text("終了日").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            // タブごとに表示するDatePicker
                            if customTabSelection == 0 {
                                DatePicker(
                                    "",
                                    selection: $customStartDate,
                                    in: ...customEndDate,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                            } else {
                                DatePicker(
                                    "",
                                    selection: $customEndDate,
                                    in: customStartDate...Date(),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                            }
                        }
                        .padding()
                        .presentationDetents([.height(360)])
                        .navigationTitle("期間を選択")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("完了") {
                                    showCustomDateSheet = false
                                }
                            }
                        }
                    }
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
        .onAppear {
            // 初回起動ならモーダルを出す
            if !hasShownCalendarIntegration {
                isShowCalendarIntegration = true
            }
        }
        // モーダルで連携画面を表示
        .sheet(isPresented: $isShowCalendarIntegration) {
            GoogleCalendarIntegrationView { didLink in
                if didLink {
                    isCalendarLinked = true
                }
                hasShownCalendarIntegration = true
                isShowCalendarIntegration = false
            }
        }
        // 連携失敗アラート
        .alert("連携に失敗しました", isPresented: $showSyncErrorAlert) {
            Button("再連携") {
                isShowCalendarIntegration = true
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("もう一度サインインしてください。")
        }
    }

    private func deleteDailyWorkout(at offsets: IndexSet) {
        for index in offsets {
            let dailyWorkout = dailyWorkouts[index]
            context.delete(dailyWorkout)
        }
    }
    // 例: Googleカレンダー同期処理の中で失敗時に呼ぶ
    private func onCalendarSyncFailed() {
        showSyncErrorAlert = true
    }
}

struct WorkoutRow: View {
    let daily: DailyWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formattedDate(date: daily.startDate))
                    .font(.headline)

                Spacer()

                // Googleカレンダーとの連携状態
                if daily.isSyncedToCalendar {
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

            Grid(alignment: .leading) {
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
                            records: [], isSyncedToCalendar: false)
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

/// Date を "yyyy/MM/dd" 形式の文字列に変換する関数
func formattedDate(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)  // 西暦を使う
    formatter.locale = Locale(identifier: "ja_JP")  // 日本語ロケール
    formatter.dateFormat = "yyyy/MM/dd"  // 表示形式
    return formatter.string(from: date)
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
