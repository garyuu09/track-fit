//
//  DistancePresetsEditView.swift
//  TrackFit
//
//  Extracted from WorkoutSheetView.swift
//

import SwiftUI

/// 距離プリセット編集ビュー
struct DistancePresetsEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var presetsData: Data
    @AppStorage("defaultDistance") private var defaultDistance: Double = 5.0

    @State private var presets: [Double] = []
    @State private var showAddPreset: Bool = false
    @State private var newPresetValue: String = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(presets, id: \.self) { preset in
                        HStack {
                            Button {
                                defaultDistance = preset
                            } label: {
                                Image(systemName: defaultDistance == preset ? "star.fill" : "star")
                                    .foregroundColor(defaultDistance == preset ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)

                            Text(formatDistanceLabel(preset))
                                .font(.body)
                            Spacer()
                            Text(String(format: "%.3f km", preset))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .onDelete(perform: deletePreset)
                    .onMove(perform: movePreset)
                } header: {
                    Text("よく使う距離")
                } footer: {
                    Text("左スワイプで削除、長押しで並び替えができます")
                }

                Section {
                    Button {
                        showAddPreset = true
                    } label: {
                        Label("距離を追加", systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    Button {
                        let defaults: [Double] = [3.0, 5.0, 10.0, 21.0975, 42.195]
                        presets = defaults
                        savePresets()
                    } label: {
                        Label("デフォルトに戻す", systemImage: "arrow.counterclockwise")
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("距離プリセット編集")
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
            .alert("距離を追加", isPresented: $showAddPreset) {
                TextField("距離 (km)", text: $newPresetValue)
                    .keyboardType(.decimalPad)
                Button("追加") {
                    if let value = Double(newPresetValue), value > 0 {
                        presets.append(value)
                        presets.sort()
                        savePresets()
                    }
                    newPresetValue = ""
                }
                Button("キャンセル", role: .cancel) {
                    newPresetValue = ""
                }
            } message: {
                Text("追加する距離を入力してください (km)")
            }
        }
    }

    private func loadPresets() {
        presets =
            (try? JSONDecoder().decode([Double].self, from: presetsData)) ?? [
                3.0, 5.0, 10.0, 21.0975, 42.195,
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

    private func formatDistanceLabel(_ distance: Double) -> String {
        if abs(distance - 21.0975) < 0.01 {
            return "ハーフマラソン"
        } else if abs(distance - 42.195) < 0.01 {
            return "フルマラソン"
        } else if distance == distance.rounded() {
            return String(format: "%.0f km", distance)
        } else {
            return String(format: "%.2f km", distance)
        }
    }
}
