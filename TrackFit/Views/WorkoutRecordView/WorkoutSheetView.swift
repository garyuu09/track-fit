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
    @State private var isAddingNewRecord = false
    @State private var showSaveErrorAlert = false

    @Environment(\.modelContext) private var context
    @AppStorage("isCalendarLinked") private var isCalendarLinked: Bool = false

    // 2カラムのレイアウトでカード表示
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack {
            Form {
                Section(header: Text("トレーニング日時")) {
                    dateButton(
                        title: "開始日時",
                        date: daily.startDate,
                        isPresented: $isStartSheetPresented
                    )
                    .sheet(isPresented: $isStartSheetPresented) {
                        DatePickerSheet(title: "開始日時を設定", date: $daily.startDate)
                            .presentationDetents([.fraction(0.4)])
                    }

                    dateButton(
                        title: "終了日時",
                        date: daily.endDate,
                        isPresented: $isEndSheetPresented
                    )
                    .sheet(isPresented: $isEndSheetPresented) {
                        DatePickerSheet(title: "終了日時を設定", date: $daily.endDate)
                            .presentationDetents([.fraction(0.4)])
                    }
                }
                Section(header: Text("種目情報入力")) {
                }
            }
            .frame(height: 190)
            recordsScrollView
            Spacer()
        }
        .navigationTitle("トレーニング管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    handleSave()
                }
            }
        }
        .sheet(item: $editingRecord) { rec in
            editSheet(for: rec)
        }
        .overlay(addRecordButton)
        .alert("データの保存に失敗しました", isPresented: $showSaveErrorAlert) {
            Button("再試行") {
                saveWithoutCalendar()
            }
            Button("閉じる", role: .cancel) {}
        } message: {
            Text("もう一度お試しください。")
        }
    }

    // MARK: - 日時ボタン
    private func dateButton(title: String, date: Date, isPresented: Binding<Bool>) -> some View {
        Button(action: {
            isPresented.wrappedValue = true
        }) {
            HStack {
                Text(title)
                Spacer()
                Text(DateHelper.formattedDateTime(date))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - レコード一覧
    private var recordsScrollView: some View {
        ScrollView {
            if daily.records.isEmpty {
                ContentUnavailableView(
                    "トレーニング記録がありません",
                    systemImage: "dumbbell",
                    description: Text("右下のボタンから種目を追加してトレーニングを記録しましょう！")
                )
                .padding(.top, 50)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(daily.records.indices, id: \.self) { index in
                        let record = daily.records[index]
                        WorkoutCardView(record: record)
                            .onTapGesture {
                                editingRecord = record
                                isAddingNewRecord = false
                            }
                    }
                }
                .padding()
            }
            Spacer()
        }
    }

    // MARK: - 編集シート
    private func editSheet(for rec: WorkoutRecord) -> some View {
        EditWorkoutSheetView(
            record: rec,
            modelContext: context,
            onSave: { updatedRec in
                if isAddingNewRecord {
                    daily.records.append(updatedRec)
                    isAddingNewRecord = false
                } else {
                    if let idx = daily.records.firstIndex(where: { $0.id == updatedRec.id }) {
                        daily.records[idx] = updatedRec
                    }
                }
                editingRecord = nil
            },
            onDelete: {
                if isAddingNewRecord {
                    isAddingNewRecord = false
                } else {
                    if let idx = daily.records.firstIndex(where: { $0.id == rec.id }) {
                        daily.records.remove(at: idx)
                    }
                }
                editingRecord = nil
            }
        )
        .onDisappear {
            if isAddingNewRecord {
                isAddingNewRecord = false
            }
        }
    }

    // MARK: - 追加ボタン
    private var addRecordButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    let newRecord = WorkoutRecord(
                        exerciseName: "",
                        weight: 10.0,
                        reps: 10,
                        sets: 3
                    )
                    editingRecord = newRecord
                    isAddingNewRecord = true
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
    }

    // MARK: - 保存処理
    private func handleSave() {
        if isCalendarLinked {
            saveWithCalendarSync()
        } else {
            saveWithoutCalendar()
        }
    }

    private func saveWithCalendarSync() {
        NotificationCenter.default.post(
            name: .didStartSyncingWorkout, object: daily.id)
        dismiss()
        Task { @MainActor in
            var isSaveLatestWorkout: Bool

            if daily.eventId == nil {
                isSaveLatestWorkout = await viewModel.createEvent(dailyWorkout: daily)
                if isSaveLatestWorkout, let newEventId = viewModel.eventId {
                    daily.eventId = newEventId
                }
            } else {
                isSaveLatestWorkout = await viewModel.updateEvent(dailyWorkout: daily)
            }

            if isSaveLatestWorkout {
                daily.isSyncedToCalendar = true
                do {
                    try context.save()
                } catch {
                    #if DEBUG
                        print("データ保存エラー: \(error.localizedDescription)")
                    #endif
                    daily.isSyncedToCalendar = false
                }
            } else {
                daily.isSyncedToCalendar = false
                do {
                    try context.save()
                } catch {
                    #if DEBUG
                        print("データ保存エラー: \(error.localizedDescription)")
                    #endif
                }

                let errorMsg =
                    viewModel.errorMessage ?? "カレンダーとの同期中にエラーが発生しました。"
                NotificationCenter.default.post(
                    name: .didFailSyncingWorkout,
                    object: daily.id,
                    userInfo: ["errorMessage": errorMsg]
                )
            }
            NotificationCenter.default.post(
                name: .didFinishSyncingWorkout, object: daily.id)
        }
    }

    private func saveWithoutCalendar() {
        daily.isSyncedToCalendar = false
        do {
            try context.save()
        } catch {
            #if DEBUG
                print("データ保存エラー: \(error.localizedDescription)")
            #endif
            showSaveErrorAlert = true
            return
        }
        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: .shouldShowCalendarIntegrationAlert, object: nil)
        }
    }
}

#Preview {
    @Previewable @State var dailyWorkout: DailyWorkout = DailyWorkout(
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60),
        records: [
            WorkoutRecord(exerciseName: "ベンチプレス", weight: 50.0, reps: 10, sets: 3),
            WorkoutRecord(exerciseName: "スクワット", weight: 70.0, reps: 8, sets: 3),
            WorkoutRecord(exerciseName: "デッドリフト", weight: 80.0, reps: 5, sets: 2),
        ],
        isSyncedToCalendar: true
    )
    WorkoutSheetView(daily: dailyWorkout)
}
