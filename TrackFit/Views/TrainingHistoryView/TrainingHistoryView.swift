import SwiftData
import SwiftUI

// MARK: - 履歴タイプ
enum HistoryType: String, CaseIterable {
    case exercise = "種目"
    case running = "ランニング"
}

struct TrainingHistoryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \RunningRecord.date, order: .reverse) private var runningRecords: [RunningRecord]
    @State private var searchText = ""
    @State private var selectedHistoryType: HistoryType = .exercise
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

    // 検索フィルタリングされたランニング記録
    private var filteredRunningRecords: [RunningRecord] {
        if searchText.isEmpty {
            return runningRecords
        }
        return runningRecords.filter {
            $0.runType.rawValue.localizedCaseInsensitiveContains(searchText)
                || ($0.memo?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // 月ごとにグループ化されたランニング記録
    private var groupedRunningRecords: [(month: String, records: [RunningRecord])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"

        let grouped = Dictionary(grouping: filteredRunningRecords) { record in
            formatter.string(from: record.date)
        }
        return grouped.map { (month: $0.key, records: $0.value) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: 履歴タイプ切替
                Picker("履歴タイプ", selection: $selectedHistoryType) {
                    ForEach(HistoryType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                List {
                    if selectedHistoryType == .exercise {
                        // MARK: - 種目履歴
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
                    } else {
                        // MARK: - ランニング履歴
                        ForEach(groupedRunningRecords, id: \.month) { group in
                            Section(header: Text(group.month)) {
                                ForEach(group.records) { record in
                                    NavigationLink(
                                        destination: RunningRecordFormView(editingRecord: record)
                                    ) {
                                        RunningHistoryRow(record: record)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(
                text: $searchText, isPresented: $isSearchPresented,
                prompt: selectedHistoryType == .exercise ? "種目を検索" : "ランニングを検索"
            )
            .navigationTitle("履歴")
            .overlay {
                if selectedHistoryType == .exercise {
                    if exercises.isEmpty {
                        ContentUnavailableView(
                            "種目がありません",
                            systemImage: "dumbbell",
                            description: Text("まずはトレーニング記録画面から種目を追加しましょう")
                        )
                    } else if groupedExercises.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                } else {
                    if runningRecords.isEmpty {
                        ContentUnavailableView(
                            "ランニング記録がありません",
                            systemImage: "figure.run",
                            description: Text("まずはトレーニング記録画面からランニングを記録しましょう")
                        )
                    } else if filteredRunningRecords.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
        }
    }
}

// MARK: - ランニング履歴行コンポーネント
struct RunningHistoryRow: View {
    let record: RunningRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(DateHelper.formattedDate(record.date))
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: record.runType.icon)
                        .foregroundColor(record.runType.color)
                    Text(record.runType.rawValue)
                        .font(.caption)
                        .foregroundColor(record.runType.color)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(record.runType.color.opacity(0.1))
                .cornerRadius(4)
            }

            HStack(spacing: 12) {
                Label(String(format: "%.2f km", record.distance), systemImage: "figure.run")
                Label(record.durationString, systemImage: "clock")
                Label(record.paceString, systemImage: "speedometer")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TrainingHistoryView()
}
