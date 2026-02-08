//
//  RunningInputSection.swift
//  TrackFit
//
//  Extracted from WorkoutSheetView.swift
//

import SwiftUI

/// ランニング入力フォームのセクション（距離・時間・ペース）
struct RunningInputSection: View {
    @Binding var editingDistance: Double
    @Binding var editingDurationMinutes: Int
    @Binding var editingDurationSeconds: Int
    @Binding var durationEditMode: DurationEditMode
    @Binding var showDistancePresetsEdit: Bool
    @Binding var showTimePresetsEdit: Bool
    let distancePresets: [Double]
    let timePresets: [Int]

    var body: some View {
        distanceSection
        timeSection
        paceSection
    }

    // MARK: - 距離入力セクション
    private var distanceSection: some View {
        Section {
            // プリセットボタン
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(distancePresets, id: \.self) { preset in
                        Button {
                            editingDistance = preset
                        } label: {
                            Text(formatDistanceLabel(preset))
                                .font(.subheadline)
                                .fontWeight(editingDistance == preset ? .bold : .regular)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    editingDistance == preset
                                        ? Color.accentColor
                                        : Color(.systemGray5)
                                )
                                .foregroundColor(editingDistance == preset ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }

            // 距離入力（Stepper付き）
            HStack {
                Button {
                    if editingDistance >= 0.1 {
                        editingDistance -= 0.1
                        editingDistance = (editingDistance * 10).rounded() / 10
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .disabled(editingDistance < 0.1)

                Spacer()

                TextField(
                    "距離", value: $editingDistance,
                    format: .number.precision(.fractionLength(2))
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.title2.bold())
                .frame(width: 100)

                Text("km")
                    .font(.title3)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    editingDistance += 0.1
                    editingDistance = (editingDistance * 10).rounded() / 10
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        } header: {
            HStack {
                Label("距離(km)", systemImage: "figure.run")
                Spacer()
                Button {
                    showDistancePresetsEdit = true
                } label: {
                    Text("編集")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
        }
    }

    // MARK: - 時間入力セクション
    private var timeSection: some View {
        Section {
            // 時間プリセットボタン
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(timePresets, id: \.self) { preset in
                        Button {
                            let totalSeconds =
                                editingDurationMinutes * 60 + editingDurationSeconds
                            if totalSeconds != preset {
                                editingDurationMinutes = preset / 60
                                editingDurationSeconds = preset % 60
                            }
                        } label: {
                            let totalSeconds =
                                editingDurationMinutes * 60 + editingDurationSeconds
                            Text(formatTimeLabel(preset))
                                .font(.subheadline)
                                .fontWeight(totalSeconds == preset ? .bold : .regular)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    totalSeconds == preset
                                        ? Color.accentColor
                                        : Color(.systemGray5)
                                )
                                .foregroundColor(totalSeconds == preset ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }

            // 時間入力（Stepper付き）
            VStack(spacing: 8) {
                HStack {
                    Button {
                        switch durationEditMode {
                        case .minutes:
                            if editingDurationMinutes > 0 {
                                editingDurationMinutes -= 1
                            }
                        case .seconds:
                            if editingDurationSeconds > 0 {
                                editingDurationSeconds -= 1
                            }
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(
                        (durationEditMode == .minutes && editingDurationMinutes == 0)
                            || (durationEditMode == .seconds && editingDurationSeconds == 0)
                    )

                    Spacer()

                    // 時間表示
                    HStack(spacing: 4) {
                        Text("\(editingDurationMinutes)")
                            .font(.title2.bold())
                            .foregroundColor(
                                durationEditMode == .minutes ? .primary : .secondary)
                        Text("分")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Text("\(editingDurationSeconds)")
                            .font(.title2.bold())
                            .foregroundColor(
                                durationEditMode == .seconds ? .primary : .secondary)
                        Text("秒")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        switch durationEditMode {
                        case .minutes:
                            editingDurationMinutes += 1
                        case .seconds:
                            if editingDurationSeconds < 59 {
                                editingDurationSeconds += 1
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(durationEditMode == .seconds && editingDurationSeconds >= 59)
                }

                // モード切り替えボタン
                durationModeToggle
            }
            .padding(.vertical, 4)
        } header: {
            HStack {
                Label("時間", systemImage: "timer")
                Spacer()
                Button {
                    showTimePresetsEdit = true
                } label: {
                    Text("編集")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
        }
    }

    // MARK: - モード切り替えボタン
    private var durationModeToggle: some View {
        HStack(spacing: 12) {
            Button {
                durationEditMode = .minutes
            } label: {
                Text("分")
                    .font(.subheadline)
                    .fontWeight(durationEditMode == .minutes ? .bold : .regular)
                    .foregroundColor(durationEditMode == .minutes ? .white : .primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(
                        durationEditMode == .minutes ? Color.accentColor : Color(.systemGray5)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                durationEditMode = .seconds
            } label: {
                Text("秒")
                    .font(.subheadline)
                    .fontWeight(durationEditMode == .seconds ? .bold : .regular)
                    .foregroundColor(durationEditMode == .seconds ? .white : .primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(
                        durationEditMode == .seconds ? Color.accentColor : Color(.systemGray5)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - ペース表示セクション
    @ViewBuilder
    private var paceSection: some View {
        if editingDistance > 0 {
            Section(header: Label("ペース(参考)", systemImage: "speedometer")) {
                let totalSeconds = editingDurationMinutes * 60 + editingDurationSeconds
                let paceSeconds =
                    totalSeconds > 0 ? Double(totalSeconds) / editingDistance : 0
                let paceMin = Int(paceSeconds) / 60
                let paceSec = Int(paceSeconds) % 60
                Text("\(paceMin):\(String(format: "%02d", paceSec)) /km")
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - ヘルパー

    private func formatDistanceLabel(_ distance: Double) -> String {
        if abs(distance - 21.0975) < 0.01 {
            return "ハーフ"
        } else if abs(distance - 42.195) < 0.01 {
            return "フル"
        } else if distance == distance.rounded() {
            return String(format: "%.0fkm", distance)
        } else {
            return String(format: "%.1fkm", distance)
        }
    }

    private func formatTimeLabel(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(minutes)分"
        } else {
            return "\(minutes)分\(secs)秒"
        }
    }
}

/// 時間入力モード
enum DurationEditMode {
    case minutes
    case seconds
}
