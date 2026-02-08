//
//  EditWorkoutSheetView.swift
//  TrackFit
//
//  Extracted from WorkoutSheetView.swift
//

import Foundation
import SwiftData
import SwiftUI

/// トレーニング編集用シート（Picker種目選択機能付き）
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

    // 時間入力モード
    @State private var durationEditMode: DurationEditMode = .minutes

    // 距離プリセット
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

    // 時間プリセット
    @State private var showTimePresetsEdit: Bool = false
    @AppStorage("timePresets") private var timePresetsData: Data = {
        let defaults: [Int] = [600, 1200, 1800, 3600, 5400]
        return (try? JSONEncoder().encode(defaults)) ?? Data()
    }()
    @AppStorage("defaultTime") private var defaultTime: Int = 1800

    private var timePresets: [Int] {
        (try? JSONDecoder().decode([Int].self, from: timePresetsData)) ?? [
            600, 1200, 1800, 3600, 5400,
        ]
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

        self._editingExerciseName = State(initialValue: record.exerciseName)
        self._editingWeight = State(initialValue: record.weight ?? 10.0)
        self._editingReps = State(initialValue: record.reps ?? 10)
        self._editingSets = State(initialValue: record.sets ?? 3)

        self._editingIsRunning = State(initialValue: record.isRunning)
        self._editingDistance = State(initialValue: record.distance ?? 5.0)
        let totalSeconds = record.durationSeconds ?? 1800
        self._editingDurationMinutes = State(initialValue: totalSeconds / 60)
        self._editingDurationSeconds = State(initialValue: totalSeconds % 60)
    }

    private var exerciseOptions: [String] {
        var options: [String] = []
        if editingExerciseName.isEmpty {
            options.append("種目を選択")
        }
        options.append("ラン")
        options.append(contentsOf: exerciseViewModel.exercises.map { $0.name }.sorted())
        options.append("新しい種目を追加...")
        return options
    }

    var body: some View {
        NavigationStack {
            Form {
                exerciseNameSection
                if editingIsRunning {
                    RunningInputSection(
                        editingDistance: $editingDistance,
                        editingDurationMinutes: $editingDurationMinutes,
                        editingDurationSeconds: $editingDurationSeconds,
                        durationEditMode: $durationEditMode,
                        showDistancePresetsEdit: $showDistancePresetsEdit,
                        showTimePresetsEdit: $showTimePresetsEdit,
                        distancePresets: distancePresets,
                        timePresets: timePresets
                    )
                } else {
                    weightTrainingSection
                }
                deleteSection
            }
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveRecord()
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

    // MARK: - 種目名セクション
    private var exerciseNameSection: some View {
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
                handleExerciseSelection(newValue)
            }
        }
    }

    // MARK: - 筋トレ入力セクション
    private var weightTrainingSection: some View {
        Group {
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
                    Stepper(value: $editingReps, in: 1...100, step: 1) {
                        Text("\(editingReps) 回")
                            .foregroundColor(.primary)
                    }
                }
            }
            Section(header: Label("セット数", systemImage: "number")) {
                HStack {
                    Spacer()
                    Stepper(value: $editingSets, in: 1...20, step: 1) {
                        Text("\(editingSets) セット")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    // MARK: - 削除セクション
    private var deleteSection: some View {
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

    // MARK: - Private Methods

    private func handleExerciseSelection(_ newValue: String) {
        if newValue == "新しい種目を追加..." {
            isShowingNewExercise = true
            selectedExerciseName =
                editingExerciseName.isEmpty ? "種目を選択" : editingExerciseName
        } else if newValue != "種目を選択" {
            editingExerciseName = newValue
            selectedExerciseName = newValue
            if newValue == "ラン" {
                editingIsRunning = true
            } else if let selectedExercise = exerciseViewModel.exercises.first(where: {
                $0.name == newValue
            }) {
                editingIsRunning = selectedExercise.isRunning
            } else {
                editingIsRunning = false
            }
        }
    }

    private func saveRecord() {
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

    private func deleteCurrentExercise() {
        if let exerciseToDelete = exerciseViewModel.exercises.first(where: {
            $0.name == editingExerciseName
        }) {
            exerciseViewModel.deleteExercise(exerciseToDelete)
            exerciseViewModel.fetchExercises()
            editingExerciseName = ""
            selectedExerciseName = "種目を選択"
        }
    }
}
