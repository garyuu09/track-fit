//
//  ExerciseSelectionView.swift
//  TrackFit
//
//  Created by Ryuga on 2025/06/13.
//

import SwiftData
import SwiftUI

struct ExerciseSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var exerciseViewModel: ExerciseViewModel
    @Environment(\.dismiss) private var dismiss

    let onExerciseSelected: (Exercise) -> Void
    @State private var searchText = ""
    @State private var isShowingExerciseManagement = false

    init(modelContext: ModelContext, onExerciseSelected: @escaping (Exercise) -> Void) {
        self._exerciseViewModel = StateObject(
            wrappedValue: ExerciseViewModel(modelContext: modelContext))
        self.onExerciseSelected = onExerciseSelected
    }

    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exerciseViewModel.exercises
        } else {
            return exerciseViewModel.exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText)
                    || exercise.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var filteredCategories: [String] {
        let categories = Set(filteredExercises.map { $0.category })
        return Array(categories).sorted()
    }

    var body: some View {
        NavigationView {
            VStack {
                if exerciseViewModel.exercises.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("トレーニング種目がありません")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("まずは種目を追加してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button("種目を追加") {
                            isShowingExerciseManagement = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if filteredCategories.isEmpty {
                            Text("検索結果がありません")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(filteredCategories, id: \.self) { category in
                                Section(category) {
                                    ForEach(exercisesForCategory(category)) { exercise in
                                        ExerciseSelectionRowView(exercise: exercise) {
                                            onExerciseSelected(exercise)
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "種目名またはカテゴリで検索")
                }
            }
            .navigationTitle("種目を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("管理") {
                        isShowingExerciseManagement = true
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingExerciseManagement) {
            ExerciseManagementView(modelContext: modelContext)
        }
        .onAppear {
            exerciseViewModel.fetchExercises()
        }
    }

    private func exercisesForCategory(_ category: String) -> [Exercise] {
        return filteredExercises.filter { $0.category == category }
    }
}

struct ExerciseSelectionRowView: View {
    let exercise: Exercise
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if !exercise.memo.isEmpty {
                        Text(exercise.memo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
