//
//  ExerciseViewModel.swift
//  TrackFit
//
//  Created by Ryuga on 2025/06/13.
//

import Foundation
import SwiftData

@MainActor
class ExerciseViewModel: ObservableObject {
    private var modelContext: ModelContext

    @Published var exercises: [Exercise] = []
    @Published var selectedExercise: Exercise?
    @Published var isShowingAddExercise = false
    @Published var isShowingEditExercise = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchExercises()
    }

    func fetchExercises() {
        do {
            let descriptor = FetchDescriptor<Exercise>(
                sortBy: [SortDescriptor(\.name)]
            )
            exercises = try modelContext.fetch(descriptor)
        } catch {
            #if DEBUG
                print("Error fetching exercises: \(error)")
            #endif
        }
    }

    func addExercise(name: String, category: String, memo: String = "") {
        let newExercise = Exercise(name: name, category: category, memo: memo)
        modelContext.insert(newExercise)
        saveContext()
        fetchExercises()
    }

    func updateExercise(_ exercise: Exercise, name: String, category: String, memo: String) {
        exercise.updateExercise(name: name, category: category, memo: memo)
        saveContext()
        fetchExercises()
    }

    func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        saveContext()
        fetchExercises()
    }

    func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            let exercise = exercises[index]
            modelContext.delete(exercise)
        }
        saveContext()
        fetchExercises()
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
                print("Error saving context: \(error)")
            #endif
        }
    }

    // カテゴリ一覧を取得
    var categories: [String] {
        let uniqueCategories = Set(exercises.map { $0.category })
        return Array(uniqueCategories).sorted()
    }

    // カテゴリ別の種目を取得
    func exercises(for category: String) -> [Exercise] {
        return exercises.filter { $0.category == category }
    }
}
