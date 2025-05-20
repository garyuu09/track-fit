//
//  WorkoutSheetView.swift
//  TrackFit
//
//  Created by Ryuga on 2025/03/09.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - トレーニング管理画面 (NavigationStackでプッシュ遷移先)
struct WorkoutSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WorkoutViewModel = .init()
    // 親画面から受け取ったDailyWorkoutをバインディングで持つ
    // これにより直接編集が可能で、戻った時に反映される
    @Bindable var daily: DailyWorkout

    @State private var editingRecord: WorkoutRecord? = nil
    @State private var isStartSheetPresented = false
    @State private var isEndSheetPresented = false

    @Environment(\.modelContext) private var context

    // 2カラムのレイアウトでカード表示
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack {
            Form {
                Section(header: Text("トレーニング日時")) {
                    Button(action: {
                        isStartSheetPresented = true
                    }) {
                        HStack {
                            Text("開始日時")
                            Spacer()
                            Text(
                                "\(daily.startDate, style: .date) \(daily.startDate, style: .time)"
                            )
                            .foregroundColor(.secondary)
                        }
                    }
                    .sheet(isPresented: $isStartSheetPresented) {
                        DatePickerSheet(
                            title: "開始日時を設定",
                            date: $daily.startDate
                        )
                        .presentationDetents([.fraction(0.4)])
                    }

                    Button(action: {
                        isEndSheetPresented = true
                    }) {
                        HStack {
                            Text("終了日時")
                            Spacer()
                            Text("\(daily.endDate, style: .date) \(daily.endDate, style: .time)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .sheet(isPresented: $isEndSheetPresented) {
                        DatePickerSheet(
                            title: "終了日時を設定",
                            date: $daily.endDate
                        )
                        .presentationDetents([.fraction(0.4)])
                    }
                }
                Section(header: Text("種目情報入力")) {
                }
            }
            .frame(height: 190)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    // ForEachに直接$daily.records.indicesを渡すと、バインドしやすい
                    ForEach(daily.records.indices, id: \.self) { index in
                        let record = daily.records[index]
                        CardView(record: record)
                            .onTapGesture {
                                editingRecord = record
                            }
                    }
                }
                Spacer()

                    .padding()
            }

            Spacer()
        }
        .navigationTitle("トレーニング管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    NotificationCenter.default.post(name: .didStartSyncingWorkout, object: daily.id)
                    dismiss()
                    Task {
                        let success = await viewModel.createEvent(dailyWorkout: daily)
                        if success {
                            daily.isSyncedToCalendar = true
                            try? context.save()
                        }
                        NotificationCenter.default.post(
                            name: .didFinishSyncingWorkout, object: daily.id)
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
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        let newRecord = WorkoutRecord(
                            exerciseName: "新種目",
                            weight: 10,
                            reps: 10,
                            sets: 3
                        )
                        daily.records.append(newRecord)
                        editingRecord = newRecord
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 28))
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        )
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

struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var date: Date

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(title, selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                Spacer()
            }
            .navigationBarTitle(Text(title), displayMode: .inline)
            .navigationBarItems(
                trailing: Button("閉じる") {
                    dismiss()
                })
        }
    }
}

#Preview {
    @Previewable @State var dailyWorkout: DailyWorkout = DailyWorkout(
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60),  // 現在日付+60分
        records: [
            WorkoutRecord(exerciseName: "ベンチプレス", weight: 50.0, reps: 10, sets: 3),
            WorkoutRecord(exerciseName: "スクワット", weight: 70.0, reps: 8, sets: 3),
            WorkoutRecord(exerciseName: "デッドリフト", weight: 80.0, reps: 5, sets: 2),
        ],
        isSyncedToCalendar: true
    )
    WorkoutSheetView(daily: dailyWorkout)
}
