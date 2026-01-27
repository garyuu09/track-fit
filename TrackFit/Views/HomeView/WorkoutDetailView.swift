//
//  WorkoutDetailView.swift
//  TrackFit
//
//  Created by Ryuga on 2025/08/24.
//

import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
    let workout: DailyWorkout

    var body: some View {
        List {
            Section(header: Text("基本情報")) {
                LabeledContent(
                    "開始日時", value: workout.startDate.formatted(date: .numeric, time: .shortened))
                LabeledContent(
                    "終了日時", value: workout.endDate.formatted(date: .numeric, time: .shortened))
                if let eventId = workout.eventId, !eventId.isEmpty {
                    LabeledContent("カレンダー連携", value: "済み")
                }
            }

            Section(header: Text("トレーニング内容")) {
                if workout.records.isEmpty {
                    Text("記録なし")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(workout.records) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.exerciseName)
                                .font(.headline)

                            HStack {
                                Text("\(record.weight.formatted()) kg")
                                    .fontWeight(.bold)
                                Text("×")
                                Text("\(record.reps)回")
                                Text("×")
                                Text("\(record.sets)セット")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(workout.startDate.formatted(date: .abbreviated, time: .omitted))
    }
}
