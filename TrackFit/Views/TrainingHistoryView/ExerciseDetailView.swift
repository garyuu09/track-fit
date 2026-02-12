import Charts
import SwiftData
import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Query(sort: \DailyWorkout.startDate, order: .reverse) private var workouts: [DailyWorkout]

    // この種目の記録のみを抽出（日付降順）- 筋トレのみ（isRunning == false）
    private var exerciseHistory: [(date: Date, record: WorkoutRecord)] {
        var history: [(Date, WorkoutRecord)] = []
        for workout in workouts {
            // この日のワークアウトに含まれる、対象種目の記録を探す（筋トレのみ）
            let matches = workout.records.filter {
                $0.exerciseName == exercise.name && !$0.isRunning
            }
            for record in matches {
                history.append((workout.startDate, record))
            }
        }
        return history
    }

    // グラフ用: 日付昇順にならべかえ（重量がnilでないもののみ）
    private var chartData: [(date: Date, maxWeight: Double)] {
        exerciseHistory.compactMap { item in
            if let weight = item.record.weight {
                return (item.date, weight)
            }
            return nil
        }.reversed()
    }

    var body: some View {
        List {
            // MARK: - グラフセクション
            Section {
                if chartData.isEmpty {
                    Text("まだ記録がありません")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    VStack(alignment: .leading) {
                        Text("重量推移 (Max)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Chart(chartData, id: \.date) { data in
                            LineMark(
                                x: .value("日付", data.date),
                                y: .value("重量", data.maxWeight)
                            )
                            .interpolationMethod(.catmullRom)
                            .symbol(by: .value("日付", data.date))
                        }
                        .frame(height: 200)
                        .padding(.vertical)
                    }
                }
            } header: {
                Text("成長記録")
            }

            // MARK: - 履歴リストセクション
            Section {
                if exerciseHistory.isEmpty {
                    Text("記録なし")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(exerciseHistory, id: \.date) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(DateHelper.formattedDate(item.date))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(item.record.weight ?? 0, specifier: "%.1f") kg")
                                    .fontWeight(.bold)
                                Text(
                                    "\(item.record.reps ?? 0) reps × \(item.record.sets ?? 0) sets"
                                )
                                .font(.caption)
                            }
                        }
                    }
                }
            } header: {
                Text("履歴")
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
