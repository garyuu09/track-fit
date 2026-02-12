//
//  RunningRecordFormView.swift
//  TrackFit
//
//  Created by Gemini on 2026/02/01.
//

import SwiftData
import SwiftUI

// MARK: - ランニング記録入力フォーム
struct RunningRecordFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RunningViewModel()
    @AppStorage("isAppleCalendarLinked") private var isAppleCalendarLinked: Bool = false
    @AppStorage("appleCalendarIdentifier") private var appleCalendarIdentifier: String = ""

    // 編集モード用
    var editingRecord: RunningRecord?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 日付セクション
                Section(header: Text("日付")) {
                    DatePicker(
                        "日付",
                        selection: $viewModel.selectedDate,
                        displayedComponents: .date
                    )
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                }

                // MARK: - ランニング種別セクション
                Section(header: Text("種別")) {
                    Picker("ランニング種別", selection: $viewModel.selectedRunType) {
                        ForEach(RunType.allCases) { runType in
                            HStack {
                                Image(systemName: runType.icon)
                                    .foregroundColor(runType.color)
                                Text(runType.rawValue)
                            }
                            .tag(runType)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                // MARK: - 距離セクション
                Section(header: Text("距離")) {
                    HStack {
                        TextField("0.0", value: $viewModel.distance, format: .number)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                        Text("km")
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - 時間セクション
                Section(header: Text("時間")) {
                    HStack(spacing: 4) {
                        // 時間
                        Picker("時間", selection: $viewModel.hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                        .clipped()

                        Text("時")
                            .foregroundColor(.secondary)

                        // 分
                        Picker("分", selection: $viewModel.minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                        .clipped()

                        Text("分")
                            .foregroundColor(.secondary)

                        // 秒
                        Picker("秒", selection: $viewModel.seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)").tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                        .clipped()

                        Text("秒")
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 120)
                }

                // MARK: - ペース表示セクション
                Section(header: Text("ペース（自動計算）")) {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(.orange)
                        Text(viewModel.paceString)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }

                // MARK: - メモセクション
                Section(header: Text("メモ（任意）")) {
                    TextField("今日のコンディションなど", text: $viewModel.memo, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(editingRecord == nil ? "ランニング記録" : "記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRecord()
                    }
                    .disabled(!viewModel.isValidInput)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let record = editingRecord {
                    viewModel.loadForEdit(record: record)
                }
            }
        }
    }

    private func saveRecord() {
        let record: RunningRecord
        if let existing = editingRecord {
            viewModel.updateRunningRecord(existing)
            record = existing
        } else {
            record = viewModel.saveRunningRecord(context: context)
        }

        // Apple Calendar同期
        if isAppleCalendarLinked {
            syncRunningToAppleCalendar(record: record)
            do {
                try context.save()
            } catch {
                #if DEBUG
                    print("データ保存エラー: \(error.localizedDescription)")
                #endif
            }
        }

        dismiss()
    }

    private func syncRunningToAppleCalendar(record: RunningRecord) {
        let calId = appleCalendarIdentifier.isEmpty ? nil : appleCalendarIdentifier
        do {
            if let existingId = record.appleEventId {
                try AppleCalendarService.updateRunningEvent(
                    eventIdentifier: existingId,
                    record: record,
                    calendarIdentifier: calId
                )
            } else {
                let newId = try AppleCalendarService.createRunningEvent(
                    record: record,
                    calendarIdentifier: calId
                )
                record.appleEventId = newId
            }
            record.isSyncedToAppleCalendar = true
        } catch {
            record.isSyncedToAppleCalendar = false
            #if DEBUG
                print("Apple Calendar同期エラー: \(error.localizedDescription)")
            #endif
        }
    }
}

#Preview {
    RunningRecordFormView()
}
