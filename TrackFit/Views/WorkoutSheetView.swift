//
//  WorkoutSheetView.swift
//  TrackFit
//
//  Created by Ryuga on 2025/03/09.
//

import SwiftUI

// MARK: - トレーニング管理画面 (NavigationStackでプッシュ遷移先)
struct WorkoutSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WorkoutViewModel = .init()
    // 親画面から受け取ったDailyWorkoutをバインディングで持つ
    // これにより直接編集が可能で、戻った時に反映される
    @Binding var daily: DailyWorkout

    @State private var editingRecord: WorkoutRecord? = nil

    // 2カラムのレイアウトでカード表示
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                // ForEachに直接$daily.records.indicesを渡すと、バインドしやすい
                ForEach($daily.records.indices, id: \.self) { index in
                    let record = daily.records[index]
                    CardView(record: record)
                        .onTapGesture {
                            editingRecord = record
                        }
                }
            }
            .padding()
        }
        // 新規トレーニングを追加ボタン
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    let newRecord = WorkoutRecord(exerciseName: "新種目", weight: 10, reps: 10, sets: 3)
                    daily.records.append(newRecord)
                } label: {
                    Label("追加", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("トレーニング管理")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // デフォルトの戻るボタンを隠す
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // 戻るボタンが押されたときの任意の処理
                    // イベントをGoogleカレンダーに登録する
                    Task {
                    await viewModel.createEvent()
                    // TODO: 更新処理もここで行いたい。
                    }
                    // ビューを閉じる
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
        // 編集用のシート（簡易実装）
        .sheet(item: $editingRecord) { rec in
            EditWorkoutSheetView(
                record: rec,
                onSave: { updatedRec in
                    // daily.records内の要素を更新
                    if let idx = daily.records.firstIndex(where: { $0.id == updatedRec.id }) {
                        daily.records[idx] = updatedRec
                    }
                    editingRecord = nil
                },
                onDelete: {
                    if let idx = daily.records.firstIndex(where: { $0.id == rec.id }) {
                        daily.records.remove(at: idx)
                    }
                    editingRecord = nil
                }
            )
        }
    }
}

// MARK: - トレーニング1件分のカード表示
struct CardView: View {
    let record: WorkoutRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.exerciseName)
                .font(.headline)

            HStack {
                Text("\(Int(record.weight)) kg")
                Spacer()
                Text("\(record.reps) 回")
            }
            .font(.subheadline)

            Text("セット数: \(record.sets)")
                .font(.footnote)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}

// MARK: - トレーニング編集用シート(簡易的)
struct EditWorkoutSheetView: View {
    @State var record: WorkoutRecord

    var onSave: (WorkoutRecord) -> Void
    var onDelete: () -> Void

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("種目名")) {
                    TextField("種目名", text: $record.exerciseName)
                }
                Section(header: Text("重量(kg)")) {
                    TextField("重量", value: $record.weight, format: .number)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("回数")) {
                    TextField("回数", value: $record.reps, format: .number)
                        .keyboardType(.numberPad)
                }
                Section(header: Text("セット数")) {
                    TextField("セット数", value: $record.sets, format: .number)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button(role: .destructive) {
                        onDelete()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("このトレーニングを削除")
                    }
                }
            }
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    onSave(record)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
#Preview {
    @Previewable @State var dailyWorkout: DailyWorkout = DailyWorkout(
        date:  Date(),
        records: [
            WorkoutRecord(exerciseName: "ベンチプレス", weight: 50.0, reps: 10, sets: 3),
            WorkoutRecord(exerciseName: "スクワット",   weight: 70.0, reps: 8,  sets: 3),
            WorkoutRecord(exerciseName: "デッドリフト", weight: 80.0, reps: 5,  sets: 2)
        ]
    )
    WorkoutSheetView(daily: $dailyWorkout)
}
