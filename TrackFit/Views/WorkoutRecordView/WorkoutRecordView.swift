import Foundation
import SwiftData
import SwiftUI

// MARK: - メインビュー
struct WorkoutRecordView: View {
    @State private var syncingWorkoutIDs: Set<UUID> = []
    enum FilterType: String, CaseIterable, Identifiable {
        case thisWeek, lastWeek, thisMonth, all, custom
        var id: String { self.rawValue }
    }

    // カレンダー機能の有効/無効状態
    @AppStorage("isCalendarFeatureEnabled") private var isCalendarFeatureEnabled: Bool = true
    // 「連携画面を見たか？」のフラグを永続化
    @AppStorage("hasShownCalendarIntegration") private var hasShownCalendarIntegration: Bool = false
    // Googleカレンダー連携状態
    @AppStorage("isCalendarLinked") private var isCalendarLinked: Bool = false
    // バナー表示フラグ
    @AppStorage("showIntegrationBanner") private var showIntegrationBanner: Bool = true
    // 同期失敗アラート用フラグ
    @State private var showSyncErrorAlert: Bool = false
    // モーダル表示フラグ
    @State private var isShowCalendarIntegration: Bool = false
    // カレンダー連携促進アラート用フラグ
    @State private var showCalendarIntegrationPromptAlert: Bool = false

    @Query(sort: \DailyWorkout.startDate, order: .forward) private var dailyWorkouts: [DailyWorkout]
    // シートの表示・非表示を管理するフラグ
    @State private var showDatePickerSheet = false
    @State var showDatePicker: Bool = false
    @State var savedDate: Date? = nil
    @State private var showCustomDateSheet = false
    @State private var showCalendarHistory = false

    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    // 選択した日付
    @State private var selectedDate = Date()
    @State private var selectedFilter: FilterType = .thisWeek
    @State private var customStartDate: Date = {
        let now = Date()
        return Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
    }()
    @State private var customEndDate: Date = Date()
    @State private var customTabSelection: Int = 0

    private var filteredWorkouts: [DailyWorkout] {
        let calendar = Calendar.current
        let now = Date()

        let filtered: [DailyWorkout]
        switch selectedFilter {
        case .all:
            filtered = dailyWorkouts
        case .thisWeek:
            guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
                filtered = dailyWorkouts
                break
            }
            filtered = dailyWorkouts.filter { $0.startDate >= startOfWeek && $0.startDate <= now }
        case .lastWeek:
            guard let thisWeekInterval = calendar.dateInterval(of: .weekOfYear, for: now),
                let lastWeekStart = calendar.date(
                    byAdding: .weekOfYear, value: -1, to: thisWeekInterval.start)
            else {
                filtered = dailyWorkouts
                break
            }
            let lastWeekEnd = thisWeekInterval.start
            filtered = dailyWorkouts.filter {
                $0.startDate >= lastWeekStart && $0.startDate < lastWeekEnd
            }
        case .thisMonth:
            guard let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start else {
                filtered = dailyWorkouts
                break
            }
            filtered = dailyWorkouts.filter { $0.startDate >= startOfMonth && $0.startDate <= now }
        case .custom:
            filtered = dailyWorkouts.filter {
                $0.startDate >= customStartDate && $0.startDate <= customEndDate
            }
        }

        // 常に日付昇順でソート
        return filtered.sorted { $0.startDate < $1.startDate }
    }

    private var dateRangeLabel: String {
        switch selectedFilter {
        case .thisWeek:
            return "今週の記録"
        case .lastWeek:
            return "先週の記録"
        case .thisMonth:
            return "今月の記録"
        case .all:
            return "すべての記録"
        case .custom:
            return
                "\(DateHelper.formattedDate(customStartDate)) 〜 \(DateHelper.formattedDate(customEndDate)) の記録"
        }
    }

    var body: some View {
        ZStack {
            NavigationStack {
                Picker("期間フィルター", selection: $selectedFilter) {
                    Text("今週").tag(FilterType.thisWeek)
                    Text("先週").tag(FilterType.lastWeek)
                    Text("今月").tag(FilterType.thisMonth)
                    Text("全て").tag(FilterType.all)
                    Text("カスタム").tag(FilterType.custom)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // MARK: Googleカレンダー未連携バナー（カレンダー機能が有効な場合のみ表示）
                /// 永続化している`isCalendarLinked`と`hasShownCalendarIntegration`をチェック
                /// `isCalendarLinked`: Googleカレンダーとの連携状態（`true`のとき、Googleカレンダーと連携中）
                ///`hasShownCalendarIntegration`: 「連携画面を見たか？」のフラグを永続化（`true`のとき、連携画面を一度以上表示済み）
                if isCalendarFeatureEnabled && (!isCalendarLinked || !hasShownCalendarIntegration) {
                    if showIntegrationBanner {
                        AlertBannerView(
                            isShowCalendarIntegration: $isShowCalendarIntegration,
                            showIntegrationBanner: $showIntegrationBanner
                        )
                    }
                }
                // AdMobバナー広告
                AdMobBannerView()
                    .frame(height: 50)
                    .background(Color(.systemBackground))

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
                                        .foregroundColor(.accentColor)
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
                                WorkoutRow(
                                    daily: daily,
                                    isSyncing: syncingWorkoutIDs.contains(daily.id),
                                    showSyncErrorAlert: $showSyncErrorAlert,
                                    isCalendarFeatureEnabled: isCalendarFeatureEnabled
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                            }
                            .onReceive(
                                NotificationCenter.default.publisher(for: .didStartSyncingWorkout)
                            ) { notification in
                                if let id = notification.object as? UUID {
                                    syncingWorkoutIDs.insert(id)
                                }
                            }
                            .onReceive(
                                NotificationCenter.default.publisher(for: .didFinishSyncingWorkout)
                            ) { notification in
                                if let id = notification.object as? UUID {
                                    syncingWorkoutIDs.remove(id)
                                    if id == daily.id && !daily.isSyncedToCalendar {
                                        showSyncErrorAlert = true
                                    }
                                }
                            }
                            .onReceive(
                                NotificationCenter.default.publisher(
                                    for: .shouldShowCalendarIntegrationAlert)
                            ) { _ in
                                // 他のアラートが表示されていない場合のみ表示
                                if !showSyncErrorAlert && !isShowCalendarIntegration {
                                    showCalendarIntegrationPromptAlert = true
                                }
                            }
                        }
                        .onDelete(perform: deleteDailyWorkout)
                    }
                }
                .navigationTitle("トレーニング一覧")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showCalendarHistory = true
                        }) {
                            Image(systemName: "calendar")
                                .font(.title2)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
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
                        .background(Color.accentColor)
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
                    if filteredWorkouts.isEmpty {
                        if dailyWorkouts.isEmpty {
                            /// はじめての利用（まだ一度も記録がない場合）
                            ContentUnavailableView(
                                "トレーニング記録がありません",
                                systemImage: "figure.run",
                                description: Text("初めてのトレーニングを記録してみましょう！")
                            )
                        } else {
                            /// フィルター適用時で結果が空の場合
                            switch selectedFilter {
                            case .thisWeek:
                                ContentUnavailableView(
                                    "今週のトレーニング記録がありません",
                                    systemImage: "calendar.badge.plus",
                                    description: Text("今週もがんばりましょう！新しい目標にチャレンジしてみませんか？")
                                )
                            case .lastWeek:
                                ContentUnavailableView(
                                    "先週のトレーニング記録がありません",
                                    systemImage: "calendar.badge.minus",
                                    description: Text("先週は忙しかったですね。今週から新たにスタートしましょう！")
                                )
                            case .thisMonth:
                                ContentUnavailableView(
                                    "今月のトレーニング記録がありません",
                                    systemImage: "calendar.badge.plus",
                                    description: Text("新たな月のスタートです！今月の目標を立ててトレーニングを始めましょう！")
                                )
                            case .custom:
                                ContentUnavailableView(
                                    "この期間のトレーニング記録がありません",
                                    systemImage: "calendar.badge.exclamationmark",
                                    description: Text("別の期間を選択してみてください。または新しくトレーニングを始めましょう！")
                                )
                            case .all:
                                ContentUnavailableView(
                                    "トレーニング記録がありません",
                                    systemImage: "figure.run",
                                    description: Text("初めてのトレーニングを記録してみましょう！")
                                )
                            }
                        }
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
            // カレンダー機能が有効な場合のみ実行
            if isCalendarFeatureEnabled {
                // 初回起動ならモーダルを出す
                if !hasShownCalendarIntegration {
                    isShowCalendarIntegration = true
                }

                // 初回起動時の連携状態チェック
                Task {
                    await GoogleCalendarAPI.checkAndUpdateLinkingStatus()
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isCalendarFeatureEnabled {
                // フォアグラウンド復帰時に連携状態をチェック（カレンダー機能が有効な場合のみ）
                Task {
                    await GoogleCalendarAPI.checkAndUpdateLinkingStatus()
                }
            }
        }
        // モーダルで連携画面を表示（カレンダー機能が有効な場合のみ）
        .sheet(
            isPresented: Binding(
                get: { isShowCalendarIntegration && isCalendarFeatureEnabled },
                set: { isShowCalendarIntegration = $0 }
            )
        ) {
            GoogleCalendarIntegrationView(
                onFinish: { didLink in
                    if didLink {
                        isCalendarLinked = true
                    }
                    hasShownCalendarIntegration = true
                    isShowCalendarIntegration = false
                },
                showIntegrationBanner: $showIntegrationBanner
            )
        }
        // 連携失敗アラート（カレンダー機能が有効な場合のみ）
        .alert(
            "連携に失敗しました",
            isPresented: Binding(
                get: { showSyncErrorAlert && isCalendarFeatureEnabled },
                set: { showSyncErrorAlert = $0 }
            )
        ) {
            Button("再連携") {
                isShowCalendarIntegration = true
            }
            Button("キャンセル", role: .cancel) {
                showIntegrationBanner = true
            }
        } message: {
            Text("もう一度サインインしてください。")
        }
        // カレンダー連携促進アラート（カレンダー機能が有効な場合のみ）
        .alert(
            "Googleカレンダーと連携しませんか？",
            isPresented: Binding(
                get: { showCalendarIntegrationPromptAlert && isCalendarFeatureEnabled },
                set: { showCalendarIntegrationPromptAlert = $0 }
            )
        ) {
            Button("連携する") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isShowCalendarIntegration = true
                }
            }
            Button("後で連携", role: .cancel) {
                showIntegrationBanner = true
            }
        } message: {
            Text("トレーニング記録をGoogleカレンダーに同期することで、スケジュール管理がより便利になります。")
        }
        .sheet(isPresented: $showCalendarHistory) {
            WorkoutCalendarHistoryView()
        }
    }

    private func deleteDailyWorkout(at offsets: IndexSet) {
        for index in offsets {
            let dailyWorkout = dailyWorkouts[index]
            context.delete(dailyWorkout)
        }
    }
}

struct WorkoutRow: View {
    let daily: DailyWorkout
    let isSyncing: Bool
    @Binding var showSyncErrorAlert: Bool
    let isCalendarFeatureEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(DateHelper.formattedDate(daily.startDate))
                    .font(.headline)

                Spacer()

                // カレンダー機能が有効な場合のみ同期状態を表示
                if isCalendarFeatureEnabled {
                    if isSyncing {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("連携中…")
                        }
                        .font(.footnote)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    } else if daily.isSyncedToCalendar {
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
            }

            Grid(alignment: .leading) {
                ForEach(daily.records) { record in
                    GridRow {
                        Text(record.exerciseName)
                        Text("\(record.weight, specifier: "%.1f")kg")
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

extension Notification.Name {
    static let didStartSyncingWorkout = Notification.Name("didStartSyncingWorkout")
    static let didFinishSyncingWorkout = Notification.Name("didFinishSyncingWorkout")
    static let shouldShowCalendarIntegrationAlert = Notification.Name(
        "shouldShowCalendarIntegrationAlert")
}
