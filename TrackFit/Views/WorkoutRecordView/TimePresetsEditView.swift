//
//  TimePresetsEditView.swift
//  TrackFit
//
//  Extracted from WorkoutSheetView.swift
//

import SwiftUI

/// 時間プリセット編集ビュー
struct TimePresetsEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var presetsData: Data
    @AppStorage("defaultTime") private var defaultTime: Int = 1800

    @State private var presets: [Int] = []
    @State private var showAddPreset: Bool = false
    @State private var newPresetMinutes: String = ""
    @State private var newPresetSeconds: String = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(presets, id: \.self) { preset in
                        HStack {
                            Button {
                                defaultTime = preset
                            } label: {
                                Image(systemName: defaultTime == preset ? "star.fill" : "star")
                                    .foregroundColor(defaultTime == preset ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)

                            Text(formatTimeLabel(preset))
                                .font(.body)
                            Spacer()
                            Text(formatDetailTime(preset))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .onDelete(perform: deletePreset)
                    .onMove(perform: movePreset)
                } header: {
                    Text("よく使う時間")
                } footer: {
                    Text("左スワイプで削除、長押しで並び替えができます")
                }

                Section {
                    Button {
                        showAddPreset = true
                    } label: {
                        Label("時間を追加", systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    Button {
                        let defaults: [Int] = [600, 1200, 1800, 3600, 5400]
                        presets = defaults
                        savePresets()
                    } label: {
                        Label("デフォルトに戻す", systemImage: "arrow.counterclockwise")
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("時間プリセット編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadPresets()
            }
            .alert("時間を追加", isPresented: $showAddPreset) {
                TextField("分", text: $newPresetMinutes)
                    .keyboardType(.numberPad)
                TextField("秒", text: $newPresetSeconds)
                    .keyboardType(.numberPad)
                Button("追加") {
                    let minutes = Int(newPresetMinutes) ?? 0
                    let seconds = Int(newPresetSeconds) ?? 0
                    let totalSeconds = minutes * 60 + seconds
                    if totalSeconds > 0 {
                        presets.append(totalSeconds)
                        presets.sort()
                        savePresets()
                    }
                    newPresetMinutes = ""
                    newPresetSeconds = ""
                }
                Button("キャンセル", role: .cancel) {
                    newPresetMinutes = ""
                    newPresetSeconds = ""
                }
            } message: {
                Text("追加する時間を入力してください")
            }
        }
    }

    private func loadPresets() {
        presets =
            (try? JSONDecoder().decode([Int].self, from: presetsData)) ?? [
                600, 1200, 1800, 3600, 5400,
            ]
    }

    private func savePresets() {
        if let data = try? JSONEncoder().encode(presets) {
            presetsData = data
        }
    }

    private func deletePreset(at offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        savePresets()
    }

    private func movePreset(from source: IndexSet, to destination: Int) {
        presets.move(fromOffsets: source, toOffset: destination)
        savePresets()
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

    private func formatDetailTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
