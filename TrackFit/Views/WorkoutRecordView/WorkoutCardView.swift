//
//  WorkoutCardView.swift
//  TrackFit
//
//  Extracted from WorkoutSheetView.swift
//

import SwiftUI

/// トレーニング1件分のカード表示
struct WorkoutCardView: View {
    let record: WorkoutRecord
    @Environment(\.colorScheme) var colorScheme

    private var iconName: String {
        if record.isRunning {
            return "figure.run"
        }
        return "dumbbell"
    }

    private var iconColor: Color {
        record.isRunning ? .orange : .accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(record.exerciseName)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(1)
            }

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .frame(width: 50, height: 50)
                    .background(iconColor.opacity(0.1))
                    .foregroundColor(iconColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    if record.isRunning {
                        runningStats
                    } else {
                        weightTrainingStats
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .stroke(colorScheme == .dark ? Color(.systemGray4) : Color.clear, lineWidth: 0.5)
        )
        .shadow(
            color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1),
            radius: 4, x: 0, y: 2
        )
    }

    // MARK: - ランニング表示
    private var runningStats: some View {
        VStack(alignment: .leading, spacing: 4) {
            statRow(
                icon: "figure.run",
                text: String(format: "%.2fkm", record.distance ?? 0),
                color: .orange)
            statRow(icon: "timer", text: record.durationString, color: .blue)
            statRow(icon: "speedometer", text: record.paceString, color: .green)
        }
    }

    // MARK: - 筋トレ表示
    private var weightTrainingStats: some View {
        VStack(alignment: .leading, spacing: 4) {
            statRow(
                icon: "scalemass",
                text: String(format: "%.1fkg", record.weight ?? 0),
                color: .blue)
            statRow(
                icon: "arrow.triangle.2.circlepath", text: "\(record.reps ?? 0)回", color: .green)
            statRow(icon: "number", text: "\(record.sets ?? 0)セット", color: .orange)
        }
    }

    private func statRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}
