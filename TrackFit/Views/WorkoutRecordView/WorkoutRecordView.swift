import Foundation
import SwiftData
import SwiftUI

// MARK: - メインビュー
struct WorkoutRecordView: View {
    @State private var syncingWorkoutIDs: Set<UUID> = []
    // 削除確認用
    @State private var workoutToDelete: DailyWorkout?
    @State private var runningRecordToDelete: RunningRecord?

    enum WorkoutType: String, CaseIterable {
        case weightTraining = "筋トレ"
        case running = "ランニング"
    }

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
    @Query(sort: \RunningRecord.date, order: .forward) private var runningRecords: [RunningRecord]
    // ワークアウト種別切替
    @State private var selectedWorkoutType: WorkoutType = .weightTraining
    // ランニング記録フォーム表示
    @State private var showRunningForm = false
    // ランニング記録編集用
    @State private var editingRunningRecord: RunningRecord?
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

        return filtered.sorted { $0.startDate < $1.startDate }
    }

    private var filteredRunningRecords: [RunningRecord] {
        let calendar = Calendar.current
        let now = Date()

        let filtered: [RunningRecord]
        switch selectedFilter {
        case .all:
            filtered = runningRecords
        case .thisWeek:
            guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
                filtered = runningRecords
                break
            }
            filtered = runningRecords.filter { $0.date >= startOfWeek && $0.date <= now }
        case .lastWeek:
            guard let thisWeekInterval = calendar.dateInterval(of: .weekOfYear, for: now),
                let lastWeekStart = calendar.date(
                    byAdding: .weekOfYear, value: -1, to: thisWeekInterval.start)
            else {
                filtered = runningRecords
                break
            }
            let lastWeekEnd = thisWeekInterval.start
            filtered = runningRecords.filter {
                $0.date >= lastWeekStart && $0.date < lastWeekEnd
            }
        case .thisMonth:
            guard let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start else {
                filtered = runningRecords
                break
            }
            filtered = runningRecords.filter { $0.date >= startOfMonth && $0.date <= now }
        case .custom:
            filtered = runningRecords.filter {
                $0.date >= customStartDate && $0.date <= customEndDate
            }
        }

        return filtered.sorted { $0.date < $1.date }
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
                .accessibilityIdentifier("periodFilterPicker")

                // MARK: ワークアウト種別切替
                Picker("種別", selection: $selectedWorkoutType) {
                    Text("筋トレ").tag(WorkoutType.weightTraining)
                    Text("ランニング").tag(WorkoutType.running)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .accessibilityIdentifier("workoutTypePicker")

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
                    if selectedWorkoutType == .weightTraining {
                        weightTrainingListSection
                    } else {
                        runningListSection
                    }
                }
                .accessibilityIdentifier("workoutList")
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
                .safeAreaInset(edge: .bottom, alignment: .center) {
                    addTrainingButton()
                }
                .overlay {
                    if selectedWorkoutType == .weightTraining {
                        // 筋トレのempty state
                        if filteredWorkouts.isEmpty {
                            if dailyWorkouts.isEmpty {
                                ContentUnavailableView(
                                    "筋トレ記録がありません",
                                    systemImage: "dumbbell",
                                    description: Text("初めての筋トレを記録してみましょう！")
                                )
                            } else {
                                ContentUnavailableView(
                                    "この期間の筋トレ記録がありません",
                                    systemImage: "calendar.badge.exclamationmark",
                                    description: Text("別の期間を選択してみてください。")
                                )
                            }
                        }
                    } else {
                        // ランニングのempty state
                        if filteredRunningRecords.isEmpty {
                            if runningRecords.isEmpty {
                                ContentUnavailableView(
                                    "ランニング記録がありません",
                                    systemImage: "figure.run",
                                    description: Text("初めてのランニングを記録してみましょう！")
                                )
                            } else {
                                ContentUnavailableView(
                                    "この期間のランニング記録がありません",
                                    systemImage: "calendar.badge.exclamationmark",
                                    description: Text("別の期間を選択してみてください。")
                                )
                            }
                        }
                    }
                }
                .sheet(isPresented: $showDatePickerSheet) {
                    VStack(spacing: 20) {
                        Text("トレーニング日を選択してください")
                            .font(.headline)
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        Button("完了") {
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
                    customDateSheetContent()
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
            if isCalendarFeatureEnabled {
                if !hasShownCalendarIntegration {
                    isShowCalendarIntegration = true
                }
                Task {
                    await GoogleAuthService.checkAndUpdateLinkingStatus()
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isCalendarFeatureEnabled {
                Task {
                    await GoogleAuthService.checkAndUpdateLinkingStatus()
                }
            }
        }
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
        .sheet(isPresented: $showRunningForm) {
            RunningRecordFormView()
        }
        .sheet(item: $editingRunningRecord) { record in
            RunningRecordFormView(editingRecord: record)
        }
        .alert(
            "トレーニングを削除",
            isPresented: Binding(
                get: { workoutToDelete != nil },
                set: { if !$0 { workoutToDelete = nil } }
            )
        ) {
            Button("削除", role: .destructive) {
                if let workout = workoutToDelete {
                    context.delete(workout)
                    workoutToDelete = nil
                }
            }
            Button("キャンセル", role: .cancel) {
                workoutToDelete = nil
            }
        } message: {
            if let workout = workoutToDelete {
                Text(
                    "\(DateHelper.formattedDate(workout.startDate))のトレーニングを削除しますか？\nこの操作は元に戻せません。"
                )
            }
        }
        .alert(
            "ランニング記録を削除",
            isPresented: Binding(
                get: { runningRecordToDelete != nil },
                set: { if !$0 { runningRecordToDelete = nil } }
            )
        ) {
            Button("削除", role: .destructive) {
                if let record = runningRecordToDelete {
                    context.delete(record)
                    runningRecordToDelete = nil
                }
            }
            Button("キャンセル", role: .cancel) {
                runningRecordToDelete = nil
            }
        } message: {
            if let record = runningRecordToDelete {
                Text(
                    "\(DateHelper.formattedDate(record.date))のランニング記録を削除しますか？\nこの操作は元に戻せません。"
                )
            }
        }
    }

    // MARK: - Private Views

    /// 筋トレ記録リストセクション
    @ViewBuilder
    private var weightTrainingListSection: some View {
        Section(header: dateRangeSectionHeader()) {
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
                    NotificationCenter.default.publisher(for: .shouldShowCalendarIntegrationAlert)
                ) { _ in
                    if !showSyncErrorAlert && !isShowCalendarIntegration {
                        showCalendarIntegrationPromptAlert = true
                    }
                }
            }
            .onDelete(perform: deleteDailyWorkout)
        }
    }

    /// ランニング記録リストセクション
    @ViewBuilder
    private var runningListSection: some View {
        Section(header: dateRangeSectionHeader()) {
            ForEach(filteredRunningRecords) { record in
                RunningRow(
                    record: record,
                    isCalendarFeatureEnabled: isCalendarFeatureEnabled
                )
                .onTapGesture {
                    editingRunningRecord = record
                }
            }
            .onDelete(perform: deleteRunningRecord)
        }
    }

    @ViewBuilder
    private func dateRangeSectionHeader() -> some View {
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
    }

    private func customDateSheetContent() -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("", selection: $customTabSelection) {
                    Text("開始日").tag(0)
                    Text("終了日").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

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

    private func addTrainingButton() -> some View {
        Button(action: {
            if selectedWorkoutType == .weightTraining {
                showDatePicker = true
            } else {
                showRunningForm = true
            }
        }) {
            if #available(iOS 26.0, *) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .glassEffect(.regular.tint(.white).interactive())

            } else {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text(
                        selectedWorkoutType == .weightTraining
                            ? "トレーニング日を追加" : "ランニングを記録"
                    )
                    .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .clipShape(Capsule())
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: 8, x: 0, y: 4
                )
            }
        }
        .accessibilityIdentifier("addTrainingButton")
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .zIndex(1)
    }

    private func deleteDailyWorkout(at offsets: IndexSet) {
        if let index = offsets.first {
            workoutToDelete = filteredWorkouts[index]
        }
    }

    private func deleteRunningRecord(at offsets: IndexSet) {
        if let index = offsets.first {
            runningRecordToDelete = filteredRunningRecords[index]
        }
    }
}

// MARK: - プレビュー
#Preview {
    WorkoutRecordView()
}
