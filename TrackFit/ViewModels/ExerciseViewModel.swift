//
//  ExerciseViewModel.swift
//  TrackFit
//
//  Created by Ryuga on 2025/06/13.
//

import Foundation
import SwiftData

/// トレーニング種目のCRUD操作を管理するViewModel
///
/// SwiftDataの`ModelContext`を通じて`Exercise`モデルの取得・追加・更新・削除を行う。
/// カテゴリ別のグループ化機能も提供する。
@MainActor
class ExerciseViewModel: ObservableObject {
    private var modelContext: ModelContext

    @Published var exercises: [Exercise] = []
    @Published var categories: [String] = []
    @Published var selectedExercise: Exercise?
    @Published var isShowingAddExercise = false
    @Published var isShowingEditExercise = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // initでのfetchExercises呼び出しを削除
        // onAppearで呼ばれるため、ここでは不要
    }

    func fetchExercises() {
        do {
            let descriptor = FetchDescriptor<Exercise>(
                sortBy: [SortDescriptor(\.name)]
            )
            exercises = try modelContext.fetch(descriptor)
            updateCategories()
        } catch {
            #if DEBUG
                print("Error fetching exercises: \(error)")
            #endif
        }
    }

    func addExercise(name: String, category: String, memo: String = "", isRunning: Bool = false) {
        let newExercise = Exercise(name: name, category: category, memo: memo, isRunning: isRunning)
        modelContext.insert(newExercise)
        saveContext()
        // 注意: ここで配列を更新しない
        // シートのonDismissでfetchExercises()を呼び出す
    }

    func updateExercise(
        _ exercise: Exercise, name: String, category: String, memo: String, isRunning: Bool = false
    ) {
        exercise.updateExercise(name: name, category: category, memo: memo, isRunning: isRunning)
        saveContext()
        // 注意: ここで配列を更新しない
        // シートのonDismissでfetchExercises()を呼び出す
    }

    func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        saveContext()
        // 注意: ここで配列を更新しない
        // シートのonDismissでfetchExercises()を呼び出す
    }

    func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            let exercise = exercises[index]
            modelContext.delete(exercise)
        }
        saveContext()
        // 注意: ここで配列を更新しない
        // シートのonDismissでfetchExercises()を呼び出す
    }

    @discardableResult
    private func saveContext() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            #if DEBUG
                print("Error saving context: \(error)")
            #endif
            return false
        }
    }

    // カテゴリ一覧を更新
    private func updateCategories() {
        let uniqueCategories = Set(exercises.map { $0.category })
        categories = Array(uniqueCategories).sorted()
    }

    // カテゴリ別の種目を取得
    func exercises(for category: String) -> [Exercise] {
        return exercises.filter { $0.category == category }
    }
}
