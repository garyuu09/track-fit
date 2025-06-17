//
//  ExerciseManagementView.swift
//  TrackFit
//
//  Created by Ryuga on 2025/06/13.
//

import SwiftData
import SwiftUI

struct ExerciseManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var exerciseViewModel: ExerciseViewModel
    @Environment(\.dismiss) private var dismiss

    init(modelContext: ModelContext) {
        self._exerciseViewModel = StateObject(
            wrappedValue: ExerciseViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationView {
            List {
                if !exerciseViewModel.categories.isEmpty {
                    ForEach(exerciseViewModel.categories, id: \.self) { category in
                        Section(category) {
                            ForEach(exerciseViewModel.exercises(for: category)) { exercise in
                                ExerciseRowView(exercise: exercise) {
                                    exerciseViewModel.selectedExercise = exercise
                                    exerciseViewModel.isShowingEditExercise = true
                                }
                            }
                            .onDelete { offsets in
                                let exercisesToDelete = offsets.map {
                                    exerciseViewModel.exercises(for: category)[$0]
                                }
                                for exercise in exercisesToDelete {
                                    exerciseViewModel.deleteExercise(exercise)
                                }
                            }
                        }
                    }
                }
            }
            .overlay {
                if exerciseViewModel.categories.isEmpty {
                    ContentUnavailableView(
                        "トレーニング種目がありません",
                        systemImage: "dumbbell",
                        description: Text("種目を追加してトレーニングを始めましょう！右上のボタンから新しい種目を追加できます。")
                    )
                }
            }
            .navigationTitle("種目管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        exerciseViewModel.isShowingAddExercise = true
                    }
                }
            }
        }
        .sheet(isPresented: $exerciseViewModel.isShowingAddExercise) {
            ExerciseFormView(
                title: "新しい種目を追加",
                exercise: nil,
                onSave: { name, category, memo in
                    exerciseViewModel.addExercise(name: name, category: category, memo: memo)
                },
                onDelete: nil
            )
        }
        .sheet(isPresented: $exerciseViewModel.isShowingEditExercise) {
            if let exercise = exerciseViewModel.selectedExercise {
                ExerciseFormView(
                    title: "種目を編集",
                    exercise: exercise,
                    onSave: { name, category, memo in
                        exerciseViewModel.updateExercise(
                            exercise, name: name, category: category, memo: memo)
                    },
                    onDelete: {
                        exerciseViewModel.deleteExercise(exercise)
                        exerciseViewModel.selectedExercise = nil
                        exerciseViewModel.isShowingEditExercise = false
                    }
                )
            }
        }
        .onAppear {
            exerciseViewModel.fetchExercises()
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    let onEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                if !exercise.memo.isEmpty {
                    Text(exercise.memo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .contentShape(Rectangle())
    }
}

struct ExerciseFormView: View {
    let title: String
    let exercise: Exercise?
    let onSave: (String, String, String) -> Void
    let onDelete: (() -> Void)?

    @State private var name: String = ""
    @State private var category: String = ""
    @State private var memo: String = ""
    @State private var isShowingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    // よく使われるカテゴリの候補
    private let commonCategories = [
        "胸", "背中", "肩", "腕", "脚", "腹筋", "有酸素", "その他",
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("種目名", text: $name)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("カテゴリ")
                            .font(.headline)
                        TextField("カテゴリ", text: $category)

                        Text("よく使われるカテゴリ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8
                        ) {
                            ForEach(commonCategories, id: \.self) { commonCategory in
                                Button(action: {
                                    category = commonCategory
                                }) {
                                    Text(commonCategory)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            category == commonCategory
                                                ? Color.accentColor : Color.gray.opacity(0.2)
                                        )
                                        .foregroundColor(
                                            category == commonCategory ? .white : .primary
                                        )
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                Section("メモ") {
                    TextField("メモ（任意）", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                // 削除ボタン（編集時のみ表示）
                if exercise != nil, onDelete != nil {
                    Section {
                        Button(action: {
                            isShowingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("この種目を削除")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(name, category, memo)
                        dismiss()
                    }
                    .disabled(name.isEmpty || category.isEmpty)
                }
            }
        }
        .alert("種目を削除", isPresented: $isShowingDeleteConfirmation) {
            Button("削除", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("種目「\(name)」を削除しますか？\nこの操作は元に戻せません。")
        }
        .onAppear {
            if let exercise = exercise {
                name = exercise.name
                category = exercise.category
                memo = exercise.memo
            }
        }
    }
}
