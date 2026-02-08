//
//  WeightPickerSheet.swift
//  TrackFit
//
//  Extracted from WorkoutSheetView.swift
//

import SwiftUI

/// 重量選択用のホイールピッカーシート
struct WeightPickerSheet: View {
    @Binding var weight: Double
    let weightOptions: [Double]
    @Environment(\.dismiss) private var dismiss

    // 整数部分と小数部分を分けて管理
    @State private var integerPart: Int
    @State private var decimalPart: Int

    // 整数部分の選択肢（0kg～200kg）
    private let integerOptions = Array(0...200)
    // 小数部分の選択肢（0.0, 0.1, 0.2, ..., 0.9）
    private let decimalOptions = Array(0...9)

    init(weight: Binding<Double>, weightOptions: [Double]) {
        self._weight = weight
        self.weightOptions = weightOptions

        // 現在の重量から整数部分と小数部分を分離
        let currentWeight = weight.wrappedValue
        self._integerPart = State(initialValue: Int(currentWeight))
        self._decimalPart = State(
            initialValue: Int((currentWeight - Double(Int(currentWeight))) * 10 + 0.5))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack(spacing: 0) {
                    Picker("整数部分", selection: $integerPart) {
                        ForEach(integerOptions, id: \.self) { value in
                            Text("\(value)")
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)

                    Text(".")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)

                    Picker("小数部分", selection: $decimalPart) {
                        ForEach(decimalOptions, id: \.self) { value in
                            Text("\(value)")
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 60)

                    Text("kg")
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.leading, 8)
                }
                .frame(height: 200)

                Text(
                    "選択中: \(Double(integerPart) + Double(decimalPart) / 10.0, specifier: "%.1f")kg"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)

                Spacer()
            }
            .navigationTitle("重量を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        weight = Double(integerPart) + Double(decimalPart) / 10.0
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.5)])
    }
}
