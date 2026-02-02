import SwiftData
import SwiftUI

struct TrainingHistoryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @Binding var isSearchPresented: Bool

    init(isSearchPresented: Binding<Bool> = .constant(false)) {
        self._isSearchPresented = isSearchPresented
    }

    // カテゴリごとにグループ化された種目リスト
    private var groupedExercises: [(category: String, exercises: [Exercise])] {
        let filtered = exercises.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
        let grouped = Dictionary(grouping: filtered, by: { $0.category })
        return grouped.map { (category: $0.key, exercises: $0.value) }
            .sorted { $0.category < $1.category }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedExercises, id: \.category) { group in
                    Section(header: Text(group.category)) {
                        ForEach(group.exercises) { exercise in
                            NavigationLink(
                                destination: ExerciseDetailView(exercise: exercise)
                            ) {
                                VStack(alignment: .leading) {
                                    Text(exercise.name)
                                        .font(.headline)
                                    if !exercise.memo.isEmpty {
                                        Text(exercise.memo)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(
                text: $searchText, isPresented: $isSearchPresented,
                prompt: "種目を検索"
            )
            .navigationTitle("履歴")
            .overlay {
                if exercises.isEmpty {
                    ContentUnavailableView(
                        "種目がありません",
                        systemImage: "dumbbell",
                        description: Text("まずはトレーニング記録画面から種目を追加しましょう")
                    )
                } else if groupedExercises.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
}

#Preview {
    TrainingHistoryView()
}
