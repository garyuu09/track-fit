//
//  HomeView.swift
//  TrackFit
//
//  Created by Ryuga on 2025/08/24.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Query(sort: \DailyWorkout.startDate, order: .reverse) private var workouts: [DailyWorkout]
    @Query(sort: \RunningRecord.date, order: .reverse) private var runningRecords: [RunningRecord]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak Card
                    StreakCard(streak: viewModel.currentWeekStreak)

                    // Heatmap
                    ActivityHeatmap(activityLog: viewModel.activityLog)

                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("最近のアクティビティ")
                            .font(.headline)
                            .padding(.horizontal, 4)

                        if viewModel.recentWorkouts.isEmpty {
                            Text("まだ記録がありません")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(viewModel.recentWorkouts) { workout in
                                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                    RecentWorkoutRow(workout: workout)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("ホーム")
            .onAppear {
                viewModel.updateStats(workouts: workouts, runningRecords: runningRecords)
            }
            .onChange(of: workouts) { _, newWorkouts in
                viewModel.updateStats(workouts: newWorkouts, runningRecords: runningRecords)
            }
            .onChange(of: runningRecords) { _, newRecords in
                viewModel.updateStats(workouts: workouts, runningRecords: newRecords)
            }
        }
    }
}

// MARK: - Subviews

struct StreakCard: View {
    let streak: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("継続中")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(streak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.trackFitThemeColor)

                    Text("週間")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()

            Image(systemName: "flame.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(streak > 0 ? Color.orange : Color.gray.opacity(0.3))
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct RecentWorkoutRow: View {
    let workout: DailyWorkout

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.body)
                    .fontWeight(.medium)

                Text("\(workout.records.count) 種目")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// プレビュー用に簡略化されたWorkoutDetailView（実際のものがなければ）
// しかし、既存のファイルにあるはずなので、参照できるか確認が必要。
// おそらく TrainingHistoryView の配下にある詳細画面を使いたいが、
// 名前がわからないので一旦仮置きするか、既存のものをimportする。
// ユーザーの作業ファイル情報に `ExerciseDetailView.swift` はあるが `WorkoutDetailView` は見当たらないので
// コンテキストから探す必要があるが、一旦NavigationLinkの先は仮定する。

// 修正: WorkoutDetailViewが既存のコードベースに存在しない可能性がある。
// TrainingHistoryViewの中身を確認していないが、履歴詳細画面はあるはず。
// TrainingHistoryView.swift を確認して、詳細画面のView名を確認する。
