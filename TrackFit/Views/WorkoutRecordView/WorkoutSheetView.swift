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
                            Text(
                                "\(daily.startDate, style: .date) \(daily.startDate, style: .time)"
                            )
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
                            Text("\(daily.endDate, style: .date) \(daily.endDate, style: .time)")
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
                            let isSaveLatestWorkout = await viewModel.updateEvent(
                                dailyWorkout: daily)
                            if isSaveLatestWorkout {
                                daily.isSyncedToCalendar = true
                                do {
                                    try context.save()
                                } catch {
                                    print("データ保存エラー: \(error.localizedDescription)")
                                    daily.isSyncedToCalendar = false
                                }
                            } else {
                                // 更新失敗時は同期状態をfalseに設定
                                daily.isSyncedToCalendar = false
                                do {
                                    try context.save()
                                } catch {
                                    print("データ保存エラー: \(error.localizedDescription)")
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
                            print("データ保存エラー: \(error.localizedDescription)")
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
                            weight: 10,
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

    private var iconName: String {
        switch record.exerciseName {
        case "ベンチプレス": return "figure.strengthtraining.traditional"
        case "スクワット": return "figure.strengthtraining.functional"
        case "デッドリフト": return "figure.barbell"
        case "チェストプレス": return "figure.strengthtraining.traditional"
        case "ラットプルダウン": return "figure.pullup"
        default: return "dumbbell"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(record.exerciseName)
                    .font(.headline)
            }

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(Color.accentColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "scalemass")
                        Text("\(Int(record.weight)) kg")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.blue)

                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("\(record.reps) 回")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.green)

                    HStack(spacing: 6) {
                        Image(systemName: "number")
                        Text("\(record.sets) セット")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.orange)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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

    // 編集用の一時的な状態
    @State private var editingExerciseName: String
    @State private var editingWeight: Double
    @State private var editingReps: Int
    @State private var editingSets: Int

    // 重量の選択肢（2.5kg刻み、2.5kg～200kg）
    private var weightOptions: [Double] {
        return Array(stride(from: 2.5, through: 200.0, by: 2.5))
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

        // 編集用の一時状態を初期化
        self._editingExerciseName = State(initialValue: record.exerciseName)
        self._editingWeight = State(initialValue: record.weight)
        self._editingReps = State(initialValue: record.reps)
        self._editingSets = State(initialValue: record.sets)
    }

    private var exerciseOptions: [String] {
        var options: [String] = []
        if editingExerciseName.isEmpty {
            options.append("種目を選択")
        }
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
                                .foregroundColor(.blue)
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
                        } else {
                            editingExerciseName = newValue
                            selectedExerciseName = newValue
                        }
                    }
                }
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
                    // 編集された値でレコードを更新
                    let updatedRecord = WorkoutRecord(
                        exerciseName: editingExerciseName,
                        weight: editingWeight,
                        reps: editingReps,
                        sets: editingSets
                    )
                    updatedRecord.id = originalRecord.id
                    onSave(updatedRecord)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $isShowingNewExercise) {
                ExerciseFormView(
                    title: "新しい種目を追加",
                    exercise: nil,
                    onSave: { name, category, memo in
                        exerciseViewModel.addExercise(name: name, category: category, memo: memo)
                        exerciseViewModel.fetchExercises()
                        selectedExerciseName = name
                        editingExerciseName = name
                    },
                    onDelete: nil
                )
            }
            .sheet(isPresented: $isShowingWeightPicker) {
                WeightPickerSheet(weight: $editingWeight, weightOptions: weightOptions)
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
}

// MARK: - 重量選択用シート
struct WeightPickerSheet: View {
    @Binding var weight: Double
    let weightOptions: [Double]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Picker("重量を選択", selection: $weight) {
                    ForEach(weightOptions, id: \.self) { weightOption in
                        Text("\(weightOption, specifier: "%.1f") kg")
                            .tag(weightOption)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 300)

                Spacer()
            }
            .navigationTitle("重量を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.4)])
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
