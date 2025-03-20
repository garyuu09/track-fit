//
//  WorkoutEditView.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/30.
//

import SwiftUI

struct WorkoutEditView: View {
  @StateObject private var viewModel = WorkoutViewModel()
  @FocusState private var focusedField: Field?

  enum Field: Hashable {
    case exerciseName
    case weight
  }

  // 実際には、親Viewやログイン後の画面から accessToken を注入する想定
  let accessToken: String
  let isUpdateMode: Bool  // true: 更新モード, false: 新規作成モード
  let existingEventId: String?  // 更新モードの場合のみ設定

  var body: some View {
    VStack(spacing: 20) {
      // 日付選択
      DatePicker("トレーニング日", selection: $viewModel.date, displayedComponents: .date)
        .padding()

      // 種目 (TextField)
      TextField("トレーニング種目", text: $viewModel.exerciseName)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
        .focused($focusedField, equals: .exerciseName)
        .onTapGesture {
          focusedField = .exerciseName
        }

      // 重量 (TextField)
      TextField("重量(kg)", text: $viewModel.weight)
        .keyboardType(.decimalPad)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
        .focused($focusedField, equals: .weight)
        .onTapGesture {
          focusedField = .weight
        }

      // セット数 (Stepper)
      Stepper("セット数: \(viewModel.sets)", value: $viewModel.sets, in: 1...10)
        .padding()

      // 回数 (Stepper)
      Stepper("回数: \(viewModel.reps)", value: $viewModel.reps, in: 1...50)
        .padding()

      if viewModel.isLoading {
        ProgressView("通信中...")
      } else {
        // 追加 or 更新ボタン
        Button(isUpdateMode ? "イベント更新" : "新規追加") {
          Task {
            if isUpdateMode {
              await viewModel.updateEvent()
            } else {
              //                            await viewModel.createEvent()
            }
          }
        }
        .padding()
      }

      // エラー表示
      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .padding()
      }
    }
    .frame(
      width: UIScreen.main.bounds.width,
      height: UIScreen.main.bounds.height
    )
    .contentShape(RoundedRectangle(cornerRadius: 10))
    .onTapGesture {
      focusedField = nil
    }
    .navigationTitle(isUpdateMode ? "イベントを更新" : "イベントを追加")
    .onAppear {
      // アクセストークンを注入
      viewModel.accessToken = accessToken

      // 更新モードなら、既存イベントIDをセット
      if isUpdateMode, let eid = existingEventId {
        viewModel.eventId = eid
      }
    }
  }
}

//#Preview {
//    WorkoutEditView()
//}
