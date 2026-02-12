import SwiftData
import SwiftUI

struct TrainingHistoryView: View {
    enum HistoryType: String, CaseIterable {
        case exercise = "種目"
        case running = "ランニング"
    }

    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \RunningRecord.date, order: .reverse) private var runningRecords: [RunningRecord]
    @State private var searchText = ""
    @State private var selectedHistoryType: HistoryType = .exercise
    @State private var selectedRunType: RunType?
    @Binding var isSearchPresented: Bool

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

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

    // フィルタ・検索済みランニング記録
    private var filteredRunningRecords: [RunningRecord] {
        var records = runningRecords
        if let runType = selectedRunType {
            records = records.filter { $0.runType == runType }
        }
        if !searchText.isEmpty {
            records = records.filter {
                $0.runType.rawValue.localizedCaseInsensitiveContains(searchText)
                    || ($0.memo ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        return records
    }

    // 月ごとにグループ化されたランニング記録
    private var groupedRunningRecords: [(month: String, records: [RunningRecord])] {
        let grouped = Dictionary(grouping: filteredRunningRecords) { record in
            Self.monthFormatter.string(from: record.date)
        }
        return grouped.map { (month: $0.key, records: $0.value) }
            .sorted { $0.records[0].date > $1.records[0].date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - 種別切替
                Picker("履歴種別", selection: $selectedHistoryType) {
                    Text("種目").tag(HistoryType.exercise)
                    Text("ランニング").tag(HistoryType.running)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // MARK: - ランニング種別フィルター
                if selectedHistoryType == .running {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                label: "すべて",
                                isSelected: selectedRunType == nil
                            ) {
                                selectedRunType = nil
                            }
                            ForEach(RunType.allCases) { runType in
                                FilterChip(
                                    label: runType.rawValue,
                                    icon: runType.icon,
                                    color: runType.color,
                                    isSelected: selectedRunType == runType
                                ) {
                                    selectedRunType = runType
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 4)
                }

                // MARK: - リスト
                List {
                    if selectedHistoryType == .exercise {
                        ForEach(groupedExercises, id: \.category) { group in
                            Section(
                                header: HStack(spacing: 6) {
                                    Image(
                                        systemName: ExerciseCategoryIcon.icon(
                                            for: group.category)
                                    )
                                    .foregroundColor(
                                        ExerciseCategoryIcon.color(for: group.category))
                                    Text(group.category)
                                }
                            ) {
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
                        ForEach(groupedRunningRecords, id: \.month) { group in
                            Section(header: Text(group.month)) {
                                ForEach(group.records) { record in
                                    RunningHistoryRow(record: record)
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
                            description: Text("トレーニング記録画面からランニングを記録しましょう")
                        )
                    } else if filteredRunningRecords.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
        }
    }
}

// MARK: - ランニング履歴行
struct RunningHistoryRow: View {
    let record: RunningRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(DateHelper.formattedDate(record.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: record.runType.icon)
                        .foregroundColor(record.runType.color)
                    Text(record.runType.rawValue)
                        .font(.caption)
                        .foregroundColor(record.runType.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(record.runType.color.opacity(0.1))
                .cornerRadius(8)
            }

            HStack(spacing: 16) {
                Label(String(format: "%.2f km", record.distance), systemImage: "location")
                Label(record.durationString, systemImage: "clock")
                Label(record.paceString, systemImage: "speedometer")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            if let memo = record.memo, !memo.isEmpty {
                Text(memo)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - フィルターチップ
struct FilterChip: View {
    let label: String
    var icon: String? = nil
    var color: Color = .accentColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? color : .secondary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
    }
}

#Preview {
    TrainingHistoryView()
}
