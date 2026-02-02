//
//  WorkoutSheetView.swift
//  TrackFit
//
//  Created by Ryuga on 2025/03/09.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - トレーニング管理画面 (NavigationStackでプッシュ遷移先)
struct WorkoutSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WorkoutViewModel = .init()
    // 親画面から受け取ったDailyWorkoutをバインディングで持つ
    // これにより直接編集が可能で、戻った時に反映される
    @Bindable var daily: DailyWorkout

    @State private var editingRecord: WorkoutRecord? = nil
    @State private var isStartSheetPresented = false
    @State private var isEndSheetPresented = false
    @State private var isAddingNewRecord = false

    @Environment(\.modelContext) private var context
    @AppStorage("isCalendarLinked") private var isCalendarLinked: Bool = false

    // 2カラムのレイアウトでカード表示
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack {
            Form {
                Section(header: Text("トレーニング日時")) {
                    Button(action: {
                        isStartSheetPresented = true
                    }) {
                        HStack {
                            Text("開始日時")
                            Spacer()
                            Text(DateHelper.formattedDateTime(daily.startDate))
                                .foregroundColor(.secondary)
                        }
                    }
                    .sheet(isPresented: $isStartSheetPresented) {
                        DatePickerSheet(
                            title: "開始日時を設定",
                            date: $daily.startDate
                        )
                        .presentationDetents([.fraction(0.4)])
                    }

                    Button(action: {
                        isEndSheetPresented = true
                    }) {
                        HStack {
                            Text("終了日時")
                            Spacer()
                            Text(DateHelper.formattedDateTime(daily.endDate))
                                .foregroundColor(.secondary)
                        }
                    }
                    .sheet(isPresented: $isEndSheetPresented) {
                        DatePickerSheet(
                            title: "終了日時を設定",
                            date: $daily.endDate
                        )
                        .presentationDetents([.fraction(0.4)])
                    }
                }
                Section(header: Text("種目情報入力")) {
                }
            }
            .frame(height: 190)
            ScrollView {
                if daily.records.isEmpty {
                    ContentUnavailableView(
                        "トレーニング記録がありません",
                        systemImage: "dumbbell",
                        description: Text("右下のボタンから種目を追加してトレーニングを記録しましょう！")
                    )
                    .padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        // ForEachに直接$daily.records.indicesを渡すと、バインドしやすい
                        ForEach(daily.records.indices, id: \.self) { index in
                            let record = daily.records[index]
                            CardView(record: record)
                                .onTapGesture {
                                    editingRecord = record
                                    isAddingNewRecord = false
                                }
                        }
                    }
                    .padding()
                }
                Spacer()
            }

            Spacer()
        }
        .navigationTitle("トレーニング管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    if isCalendarLinked {
                        // カレンダー連携済みの場合の処理
                        NotificationCenter.default.post(
                            name: .didStartSyncingWorkout, object: daily.id)
                        dismiss()
                        Task { @MainActor in
                            var isSaveLatestWorkout: Bool

                            // eventIdの有無で新規作成か更新かを判定
                            if daily.eventId == nil {
                                // 新規作成
                                isSaveLatestWorkout = await viewModel.createEvent(
                                    dailyWorkout: daily)
                                if isSaveLatestWorkout, let newEventId = viewModel.eventId {
                                    daily.eventId = newEventId
                                }
                            } else {
                                // 既存イベントの更新
                                isSaveLatestWorkout = await viewModel.updateEvent(
                                    dailyWorkout: daily)
                            }

                            if isSaveLatestWorkout {
                                daily.isSyncedToCalendar = true
                                do {
                                    try context.save()
                                } catch {
                                    #if DEBUG
                                        print("データ保存エラー: \(error.localizedDescription)")
                                    #endif
                                    daily.isSyncedToCalendar = false
                                }
                            } else {
                                // 同期失敗時は同期状態をfalseに設定
                                daily.isSyncedToCalendar = false
                                do {
                                    try context.save()
                                } catch {
                                    #if DEBUG
                                        print("データ保存エラー: \(error.localizedDescription)")
                                    #endif
                                }

                                // エラー詳細をコンソールに出力
                                if let errorMsg = viewModel.errorMessage {
                                    #if DEBUG
                                        print("Google Calendar同期エラー: \(errorMsg)")
                                    #endif
                                }
                            }
                            NotificationCenter.default.post(
                                name: .didFinishSyncingWorkout, object: daily.id)
                        }
                    } else {
                        // カレンダー未連携の場合
                        daily.isSyncedToCalendar = false
                        do {
                            try context.save()
                        } catch {
                            #if DEBUG
                                print("データ保存エラー: \(error.localizedDescription)")
                            #endif
                        }
                        dismiss()

                        // 画面が完全に閉じられてからアラートを表示
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(
                                name: .shouldShowCalendarIntegrationAlert, object: nil)
                        }
                    }
                }
            }
        }
        // 編集用のシート
        .sheet(item: $editingRecord) { rec in
            EditWorkoutSheetView(
                record: rec,
                modelContext: context,
                onSave: { updatedRec in
                    if isAddingNewRecord {
                        // 新規追加の場合
                        daily.records.append(updatedRec)
                        isAddingNewRecord = false
                    } else {
                        // 既存レコードの更新の場合
                        if let idx = daily.records.firstIndex(where: { $0.id == updatedRec.id }) {
                            daily.records[idx] = updatedRec
                        }
                    }
                    editingRecord = nil
                },
                onDelete: {
                    if isAddingNewRecord {
                        // 新規追加中の削除は何もしない（まだdaily.recordsに追加されていない）
                        isAddingNewRecord = false
                    } else {
                        // 既存レコードの削除
                        if let idx = daily.records.firstIndex(where: { $0.id == rec.id }) {
                            daily.records.remove(at: idx)
                        }
                    }
                    editingRecord = nil
                }
            )
            .onDisappear {
                // シートが閉じられた時（キャンセル時）の処理
                if isAddingNewRecord {
                    isAddingNewRecord = false
                }
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        let newRecord = WorkoutRecord(
                            exerciseName: "",
                            weight: 10.0,
                            reps: 10,
                            sets: 3
                        )
                        editingRecord = newRecord
                        isAddingNewRecord = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 28))
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        )
    }
}

// MARK: - トレーニング1件分のカード表示
struct CardView: View {
    let record: WorkoutRecord
    @Environment(\.colorScheme) var colorScheme

    private var iconName: String {
        if record.isRunning {
            return "figure.run"
        }
        return "dumbbell"
    }

    private var iconColor: Color {
        record.isRunning ? .orange : .accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(record.exerciseName)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(1)
            }

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .frame(width: 50, height: 50)
                    .background(iconColor.opacity(0.1))
                    .foregroundColor(iconColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    if record.isRunning {
                        // ランニング表示
                        HStack(spacing: 4) {
                            Image(systemName: "figure.run")
                                .font(.caption)
                            Text("\(record.distance ?? 0, specifier: "%.2f")km")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Color.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.caption)
                            Text(record.durationString)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Color.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                        HStack(spacing: 4) {
                            Image(systemName: "speedometer")
                                .font(.caption)
                            Text(record.paceString)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Color.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    } else {
                        // 筋トレ表示
                        HStack(spacing: 4) {
                            Image(systemName: "scalemass")
                                .font(.caption)
                            Text("\(record.weight ?? 0, specifier: "%.1f")kg")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Color.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption)
                            Text("\(record.reps ?? 0)回")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Color.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                        HStack(spacing: 4) {
                            Image(systemName: "number")
                                .font(.caption)
                            Text("\(record.sets ?? 0)セット")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Color.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .stroke(colorScheme == .dark ? Color(.systemGray4) : Color.clear, lineWidth: 0.5)
        )
        .shadow(
            color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1),
            radius: 4, x: 0, y: 2
        )
    }
}

// MARK: - トレーニング編集用シート(Picker種目選択機能付き)
struct EditWorkoutSheetView: View {
    let originalRecord: WorkoutRecord
    @Environment(\.modelContext) private var modelContext
    @StateObject private var exerciseViewModel: ExerciseViewModel

    var onSave: (WorkoutRecord) -> Void
    var onDelete: () -> Void

    @Environment(\.presentationMode) private var presentationMode
    @State private var isShowingNewExercise = false
    @State private var selectedExerciseName: String
    @State private var isShowingWeightPicker = false
    @State private var isShowingDeleteConfirmation = false

    // 編集用の一時的な状態（筋トレ用）
    @State private var editingExerciseName: String
    @State private var editingWeight: Double
    @State private var editingReps: Int
    @State private var editingSets: Int

    // ランニング用の一時的な状態
    @State private var editingIsRunning: Bool
    @State private var editingDistance: Double
    @State private var editingDurationMinutes: Int
    @State private var editingDurationSeconds: Int

    // 時間入力モード（分または秒）
    @State private var durationEditMode: DurationEditMode = .minutes

    enum DurationEditMode {
        case minutes
        case seconds
    }

    // 距離プリセット編集用
    @State private var showDistancePresetsEdit: Bool = false
    @AppStorage("distancePresets") private var distancePresetsData: Data = {
        let defaults: [Double] = [3.0, 5.0, 10.0, 21.0975, 42.195]
        return (try? JSONEncoder().encode(defaults)) ?? Data()
    }()
    @AppStorage("defaultDistance") private var defaultDistance: Double = 5.0

    private var distancePresets: [Double] {
        (try? JSONDecoder().decode([Double].self, from: distancePresetsData)) ?? [
            3.0, 5.0, 10.0, 21.0975, 42.195,
        ]
    }

    // 時間プリセット編集用
    @State private var showTimePresetsEdit: Bool = false
    @AppStorage("timePresets") private var timePresetsData: Data = {
        // デフォルト: 10分, 20分, 30分, 60分, 90分（秒単位）
        let defaults: [Int] = [600, 1200, 1800, 3600, 5400]
        return (try? JSONEncoder().encode(defaults)) ?? Data()
    }()
    @AppStorage("defaultTime") private var defaultTime: Int = 1800

    private var timePresets: [Int] {
        (try? JSONDecoder().decode([Int].self, from: timePresetsData)) ?? [
            600, 1200, 1800, 3600, 5400,
        ]
    }

    // 重量の選択肢（0.1kg刻み、0.1kg～200kg）
    private var weightOptions: [Double] {
        return Array(stride(from: 0.1, through: 200.0, by: 0.1))
    }

    init(
        record: WorkoutRecord, modelContext: ModelContext,
        onSave: @escaping (WorkoutRecord) -> Void, onDelete: @escaping () -> Void
    ) {
        self.originalRecord = record
        self._exerciseViewModel = StateObject(
            wrappedValue: ExerciseViewModel(modelContext: modelContext))
        self.onSave = onSave
        self.onDelete = onDelete
        self._selectedExerciseName = State(
            initialValue: record.exerciseName.isEmpty ? "種目を選択" : record.exerciseName)

        // 編集用の一時状態を初期化（筋トレ用）
        self._editingExerciseName = State(initialValue: record.exerciseName)
        self._editingWeight = State(initialValue: record.weight ?? 10.0)
        self._editingReps = State(initialValue: record.reps ?? 10)
        self._editingSets = State(initialValue: record.sets ?? 3)

        // ランニング用の一時状態を初期化
        self._editingIsRunning = State(initialValue: record.isRunning)
        self._editingDistance = State(initialValue: record.distance ?? 5.0)
        let totalSeconds = record.durationSeconds ?? 1800  // デフォルト30分
        self._editingDurationMinutes = State(initialValue: totalSeconds / 60)
        self._editingDurationSeconds = State(initialValue: totalSeconds % 60)
    }

    private var exerciseOptions: [String] {
        var options: [String] = []
        if editingExerciseName.isEmpty {
            options.append("種目を選択")
        }
        // デフォルトで「ラン」を追加（ランニング種目として認識）
        options.append("ラン")
        options.append(contentsOf: exerciseViewModel.exercises.map { $0.name }.sorted())
        options.append("新しい種目を追加...")
        return options
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Label("種目名", systemImage: "figure.strengthtraining.traditional")) {
                    Picker("種目を選択", selection: $selectedExerciseName) {
                        ForEach(exerciseOptions, id: \.self) { exerciseName in
                            if exerciseName == "新しい種目を追加..." {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text(exerciseName)
                                }
                                .foregroundColor(.accentColor)
                                .tag(exerciseName)
                            } else if exerciseName == "種目を選択" {
                                Text(exerciseName)
                                    .foregroundColor(.secondary)
                                    .tag(exerciseName)
                            } else {
                                Text(exerciseName).tag(exerciseName)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedExerciseName) { _, newValue in
                        if newValue == "新しい種目を追加..." {
                            isShowingNewExercise = true
                            // 選択を元に戻す
                            selectedExerciseName =
                                editingExerciseName.isEmpty ? "種目を選択" : editingExerciseName
                        } else if newValue != "種目を選択" {
                            editingExerciseName = newValue
                            selectedExerciseName = newValue
                            // 「ラン」はデフォルトでランニング種目として認識
                            if newValue == "ラン" {
                                editingIsRunning = true
                            } else if let selectedExercise = exerciseViewModel.exercises.first(
                                where: {
                                    $0.name == newValue
                                })
                            {
                                editingIsRunning = selectedExercise.isRunning
                            } else {
                                editingIsRunning = false
                            }
                        }
                    }
                }

                // ランニング種目の場合は距離・時間入力、それ以外は重量・回数・セット入力
                if editingIsRunning {
                    // ランニング用入力フォーム
                    Section {
                        // プリセットボタン
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(distancePresets, id: \.self) { preset in
                                    ZStack(alignment: .topLeading) {
                                        Button {
                                            editingDistance = preset
                                        } label: {
                                            Text(formatDistanceLabel(preset))
                                                .font(.subheadline)
                                                .fontWeight(
                                                    editingDistance == preset ? .bold : .regular
                                                )
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    editingDistance == preset
                                                        ? Color.accentColor
                                                        : Color(.systemGray5)
                                                )
                                                .foregroundColor(
                                                    editingDistance == preset ? .white : .primary
                                                )
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }

                        // 距離入力（Stepper付き）
                        HStack {
                            Button {
                                if editingDistance >= 0.1 {
                                    editingDistance -= 0.1
                                    editingDistance = (editingDistance * 10).rounded() / 10
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                            .disabled(editingDistance < 0.1)

                            Spacer()

                            TextField(
                                "距離", value: $editingDistance,
                                format: .number.precision(.fractionLength(2))
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.title2.bold())
                            .frame(width: 100)

                            Text("km")
                                .font(.title3)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button {
                                editingDistance += 0.1
                                editingDistance = (editingDistance * 10).rounded() / 10
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        HStack {
                            Label("距離(km)", systemImage: "figure.run")
                            Spacer()
                            Button {
                                showDistancePresetsEdit = true
                            } label: {
                                Text("編集")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                    }

                    Section {
                        // 時間プリセットボタン
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(timePresets, id: \.self) { preset in
                                    ZStack(alignment: .topLeading) {
                                        Button {
                                            let totalSeconds =
                                                editingDurationMinutes * 60 + editingDurationSeconds
                                            if totalSeconds == preset {
                                                // 既に選択されている場合は何もしない
                                            } else {
                                                editingDurationMinutes = preset / 60
                                                editingDurationSeconds = preset % 60
                                            }
                                        } label: {
                                            let totalSeconds =
                                                editingDurationMinutes * 60 + editingDurationSeconds
                                            Text(formatTimeLabel(preset))
                                                .font(.subheadline)
                                                .fontWeight(
                                                    totalSeconds == preset ? .bold : .regular
                                                )
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    totalSeconds == preset
                                                        ? Color.accentColor
                                                        : Color(.systemGray5)
                                                )
                                                .foregroundColor(
                                                    totalSeconds == preset ? .white : .primary
                                                )
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }

                        // 時間入力（Stepper付き）
                        VStack(spacing: 8) {
                            HStack {
                                Button {
                                    switch durationEditMode {
                                    case .minutes:
                                        if editingDurationMinutes > 0 {
                                            editingDurationMinutes -= 1
                                        }
                                    case .seconds:
                                        if editingDurationSeconds > 0 {
                                            editingDurationSeconds -= 1
                                        }
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                                .disabled(
                                    (durationEditMode == .minutes && editingDurationMinutes == 0)
                                        || (durationEditMode == .seconds
                                            && editingDurationSeconds == 0)
                                )

                                Spacer()

                                // 時間表示
                                HStack(spacing: 4) {
                                    Text("\(editingDurationMinutes)")
                                        .font(.title2.bold())
                                        .foregroundColor(
                                            durationEditMode == .minutes ? .primary : .secondary)
                                    Text("分")
                                        .font(.title3)
                                        .foregroundColor(.secondary)

                                    Text("\(editingDurationSeconds)")
                                        .font(.title2.bold())
                                        .foregroundColor(
                                            durationEditMode == .seconds ? .primary : .secondary)
                                    Text("秒")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button {
                                    switch durationEditMode {
                                    case .minutes:
                                        editingDurationMinutes += 1
                                    case .seconds:
                                        if editingDurationSeconds < 59 {
                                            editingDurationSeconds += 1
                                        }
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                                .disabled(
                                    durationEditMode == .seconds && editingDurationSeconds >= 59)
                            }

                            // モード切り替えボタン
                            HStack(spacing: 12) {
                                Button {
                                    durationEditMode = .minutes
                                } label: {
                                    Text("分")
                                        .font(.subheadline)
                                        .fontWeight(durationEditMode == .minutes ? .bold : .regular)
                                        .foregroundColor(
                                            durationEditMode == .minutes ? .white : .primary
                                        )
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 6)
                                        .background(
                                            durationEditMode == .minutes
                                                ? Color.accentColor
                                                : Color(.systemGray5)
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    durationEditMode = .seconds
                                } label: {
                                    Text("秒")
                                        .font(.subheadline)
                                        .fontWeight(durationEditMode == .seconds ? .bold : .regular)
                                        .foregroundColor(
                                            durationEditMode == .seconds ? .white : .primary
                                        )
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 6)
                                        .background(
                                            durationEditMode == .seconds
                                                ? Color.accentColor
                                                : Color(.systemGray5)
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        HStack {
                            Label("時間", systemImage: "timer")
                            Spacer()
                            Button {
                                showTimePresetsEdit = true
                            } label: {
                                Text("編集")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                    }

                    // ペース表示（参考値）
                    if editingDistance > 0 {
                        Section(header: Label("ペース(参考)", systemImage: "speedometer")) {
                            let totalSeconds = editingDurationMinutes * 60 + editingDurationSeconds
                            let paceSeconds =
                                totalSeconds > 0 ? Double(totalSeconds) / editingDistance : 0
                            let paceMin = Int(paceSeconds) / 60
                            let paceSec = Int(paceSeconds) % 60
                            Text("\(paceMin):\(String(format: "%02d", paceSec)) /km")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    // 筋トレ用入力フォーム
                    Section(header: Label("重量(kg)", systemImage: "scalemass")) {
                        Button(action: {
                            isShowingWeightPicker = true
                        }) {
                            HStack {
                                Text("\(editingWeight, specifier: "%.1f") kg")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Section(header: Label("回数", systemImage: "arrow.triangle.2.circlepath")) {
                        HStack {
                            Spacer()
                            Stepper(
                                value: $editingReps,
                                in: 1...100,
                                step: 1
                            ) {
                                Text("\(editingReps) 回")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    Section(header: Label("セット数", systemImage: "number")) {
                        HStack {
                            Spacer()
                            Stepper(
                                value: $editingSets,
                                in: 1...20,
                                step: 1
                            ) {
                                Text("\(editingSets) セット")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        onDelete()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("このトレーニングを削除")
                        }
                    }
                }
            }
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    // 編集された値でレコードを更新（ランニング/筋トレで分岐）
                    let updatedRecord: WorkoutRecord
                    if editingIsRunning {
                        let totalSeconds = editingDurationMinutes * 60 + editingDurationSeconds
                        updatedRecord = WorkoutRecord(
                            exerciseName: editingExerciseName,
                            distance: editingDistance,
                            durationSeconds: totalSeconds
                        )
                    } else {
                        updatedRecord = WorkoutRecord(
                            exerciseName: editingExerciseName,
                            weight: editingWeight,
                            reps: editingReps,
                            sets: editingSets
                        )
                    }
                    updatedRecord.id = originalRecord.id
                    onSave(updatedRecord)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $isShowingNewExercise) {
                ExerciseFormView(
                    title: "新しい種目を追加",
                    exercise: nil,
                    onSave: { name, category, memo, isRunning in
                        exerciseViewModel.addExercise(
                            name: name, category: category, memo: memo, isRunning: isRunning)
                        exerciseViewModel.fetchExercises()
                        selectedExerciseName = name
                        editingExerciseName = name
                        editingIsRunning = isRunning
                    },
                    onDelete: nil
                )
            }
            .sheet(isPresented: $isShowingWeightPicker) {
                WeightPickerSheet(weight: $editingWeight, weightOptions: [])
            }
            .alert("種目を削除", isPresented: $isShowingDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    deleteCurrentExercise()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("種目「\(editingExerciseName)」を削除しますか？\nこの操作は元に戻せません。")
            }
            .onAppear {
                exerciseViewModel.fetchExercises()
            }
            .sheet(isPresented: $showDistancePresetsEdit) {
                DistancePresetsEditView(presetsData: $distancePresetsData)
            }
            .sheet(isPresented: $showTimePresetsEdit) {
                TimePresetsEditView(presetsData: $timePresetsData)
            }
        }
    }

    // 種目削除処理
    private func deleteCurrentExercise() {
        if let exerciseToDelete = exerciseViewModel.exercises.first(where: {
            $0.name == editingExerciseName
        }) {
            exerciseViewModel.deleteExercise(exerciseToDelete)
            exerciseViewModel.fetchExercises()

            // 削除後は種目選択をリセット
            editingExerciseName = ""
            selectedExerciseName = "種目を選択"
        }
    }

    // 距離ラベルフォーマット
    private func formatDistanceLabel(_ distance: Double) -> String {
        // ハーフマラソンとフルマラソンは特別表記
        if abs(distance - 21.0975) < 0.01 {
            return "ハーフ"
        } else if abs(distance - 42.195) < 0.01 {
            return "フル"
        } else if distance == distance.rounded() {
            return String(format: "%.0fkm", distance)
        } else {
            return String(format: "%.1fkm", distance)
        }
    }

    // 時間ラベルフォーマット
    private func formatTimeLabel(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(minutes)分"
        } else {
            return "\(minutes)分\(secs)秒"
        }
    }
}

// MARK: - 重量選択用シート
struct WeightPickerSheet: View {
    @Binding var weight: Double
    let weightOptions: [Double]
    @Environment(\.dismiss) private var dismiss

    // 整数部分と小数部分を分けて管理
    @State private var integerPart: Int
    @State private var decimalPart: Int

    // 整数部分の選択肢（0kg～200kg）
    private let integerOptions = Array(0...200)
    // 小数部分の選択肢（0.0, 0.1, 0.2, ..., 0.9）
    private let decimalOptions = Array(0...9)

    init(weight: Binding<Double>, weightOptions: [Double]) {
        self._weight = weight
        self.weightOptions = weightOptions

        // 現在の重量から整数部分と小数部分を分離
        let currentWeight = weight.wrappedValue
        self._integerPart = State(initialValue: Int(currentWeight))
        self._decimalPart = State(
            initialValue: Int((currentWeight - Double(Int(currentWeight))) * 10 + 0.5))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack(spacing: 0) {
                    // 整数部分のPicker
                    Picker("整数部分", selection: $integerPart) {
                        ForEach(integerOptions, id: \.self) { value in
                            Text("\(value)")
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)

                    Text(".")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)

                    // 小数部分のPicker
                    Picker("小数部分", selection: $decimalPart) {
                        ForEach(decimalOptions, id: \.self) { value in
                            Text("\(value)")
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 60)

                    Text("kg")
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.leading, 8)
                }
                .frame(height: 200)

                // 現在選択されている重量を表示
                Text(
                    "選択中: \(Double(integerPart) + Double(decimalPart) / 10.0, specifier: "%.1f")kg"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)

                Spacer()
            }
            .navigationTitle("重量を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        // 整数部分と小数部分を合成して重量を更新
                        weight = Double(integerPart) + Double(decimalPart) / 10.0
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.5)])
    }
}

struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var date: Date

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(title, selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                Spacer()
            }
            .navigationBarTitle(Text(title), displayMode: .inline)
            .navigationBarItems(
                trailing: Button("閉じる") {
                    dismiss()
                })
        }
    }
}

// MARK: - 距離プリセット編集ビュー
struct DistancePresetsEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var presetsData: Data
    @AppStorage("defaultDistance") private var defaultDistance: Double = 5.0

    @State private var presets: [Double] = []
    @State private var showAddPreset: Bool = false
    @State private var newPresetValue: String = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(presets, id: \.self) { preset in
                        HStack {
                            // 星マークボタン
                            Button {
                                defaultDistance = preset
                            } label: {
                                Image(systemName: defaultDistance == preset ? "star.fill" : "star")
                                    .foregroundColor(defaultDistance == preset ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)

                            Text(formatDistanceLabel(preset))
                                .font(.body)
                            Spacer()
                            Text(String(format: "%.3f km", preset))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .onDelete(perform: deletePreset)
                    .onMove(perform: movePreset)
                } header: {
                    Text("よく使う距離")
                } footer: {
                    Text("左スワイプで削除、長押しで並び替えができます")
                }

                Section {
                    Button {
                        showAddPreset = true
                    } label: {
                        Label("距離を追加", systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    Button {
                        // デフォルトに戻す
                        let defaults: [Double] = [3.0, 5.0, 10.0, 21.0975, 42.195]
                        presets = defaults
                        savePresets()
                    } label: {
                        Label("デフォルトに戻す", systemImage: "arrow.counterclockwise")
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("距離プリセット編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadPresets()
            }
            .alert("距離を追加", isPresented: $showAddPreset) {
                TextField("距離 (km)", text: $newPresetValue)
                    .keyboardType(.decimalPad)
                Button("追加") {
                    if let value = Double(newPresetValue), value > 0 {
                        presets.append(value)
                        presets.sort()
                        savePresets()
                    }
                    newPresetValue = ""
                }
                Button("キャンセル", role: .cancel) {
                    newPresetValue = ""
                }
            } message: {
                Text("追加する距離を入力してください (km)")
            }
        }
    }

    private func loadPresets() {
        presets =
            (try? JSONDecoder().decode([Double].self, from: presetsData)) ?? [
                3.0, 5.0, 10.0, 21.0975, 42.195,
            ]
    }

    private func savePresets() {
        if let data = try? JSONEncoder().encode(presets) {
            presetsData = data
        }
    }

    private func deletePreset(at offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        savePresets()
    }

    private func movePreset(from source: IndexSet, to destination: Int) {
        presets.move(fromOffsets: source, toOffset: destination)
        savePresets()
    }

    private func formatDistanceLabel(_ distance: Double) -> String {
        if abs(distance - 21.0975) < 0.01 {
            return "ハーフマラソン"
        } else if abs(distance - 42.195) < 0.01 {
            return "フルマラソン"
        } else if distance == distance.rounded() {
            return String(format: "%.0f km", distance)
        } else {
            return String(format: "%.2f km", distance)
        }
    }
}

// MARK: - 時間プリセット編集ビュー
struct TimePresetsEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var presetsData: Data
    @AppStorage("defaultTime") private var defaultTime: Int = 1800

    @State private var presets: [Int] = []
    @State private var showAddPreset: Bool = false
    @State private var newPresetMinutes: String = ""
    @State private var newPresetSeconds: String = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(presets, id: \.self) { preset in
                        HStack {
                            // 星マークボタン
                            Button {
                                defaultTime = preset
                            } label: {
                                Image(systemName: defaultTime == preset ? "star.fill" : "star")
                                    .foregroundColor(defaultTime == preset ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)

                            Text(formatTimeLabel(preset))
                                .font(.body)
                            Spacer()
                            Text(formatDetailTime(preset))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .onDelete(perform: deletePreset)
                    .onMove(perform: movePreset)
                } header: {
                    Text("よく使う時間")
                } footer: {
                    Text("左スワイプで削除、長押しで並び替えができます")
                }

                Section {
                    Button {
                        showAddPreset = true
                    } label: {
                        Label("時間を追加", systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    Button {
                        // デフォルトに戻す
                        let defaults: [Int] = [600, 1200, 1800, 3600, 5400]
                        presets = defaults
                        savePresets()
                    } label: {
                        Label("デフォルトに戻す", systemImage: "arrow.counterclockwise")
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("時間プリセット編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadPresets()
            }
            .alert("時間を追加", isPresented: $showAddPreset) {
                TextField("分", text: $newPresetMinutes)
                    .keyboardType(.numberPad)
                TextField("秒", text: $newPresetSeconds)
                    .keyboardType(.numberPad)
                Button("追加") {
                    let minutes = Int(newPresetMinutes) ?? 0
                    let seconds = Int(newPresetSeconds) ?? 0
                    let totalSeconds = minutes * 60 + seconds
                    if totalSeconds > 0 {
                        presets.append(totalSeconds)
                        presets.sort()
                        savePresets()
                    }
                    newPresetMinutes = ""
                    newPresetSeconds = ""
                }
                Button("キャンセル", role: .cancel) {
                    newPresetMinutes = ""
                    newPresetSeconds = ""
                }
            } message: {
                Text("追加する時間を入力してください")
            }
        }
    }

    private func loadPresets() {
        presets =
            (try? JSONDecoder().decode([Int].self, from: presetsData)) ?? [
                600, 1200, 1800, 3600, 5400,
            ]
    }

    private func savePresets() {
        if let data = try? JSONEncoder().encode(presets) {
            presetsData = data
        }
    }

    private func deletePreset(at offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        savePresets()
    }

    private func movePreset(from source: IndexSet, to destination: Int) {
        presets.move(fromOffsets: source, toOffset: destination)
        savePresets()
    }

    private func formatTimeLabel(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(minutes)分"
        } else {
            return "\(minutes)分\(secs)秒"
        }
    }

    private func formatDetailTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

#Preview {
    @Previewable @State var dailyWorkout: DailyWorkout = DailyWorkout(
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60),  // 現在日付+60分
        records: [
            WorkoutRecord(exerciseName: "ベンチプレス", weight: 50.0, reps: 10, sets: 3),
            WorkoutRecord(exerciseName: "スクワット", weight: 70.0, reps: 8, sets: 3),
            WorkoutRecord(exerciseName: "デッドリフト", weight: 80.0, reps: 5, sets: 2),
        ],
        isSyncedToCalendar: true
    )
    WorkoutSheetView(daily: dailyWorkout)
}
