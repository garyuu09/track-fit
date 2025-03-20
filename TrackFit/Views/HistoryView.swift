//
//  HistoryView.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/18.
//

import SwiftUI

struct HistoryView: View {
  @StateObject private var viewModel = CalendarViewModel()
  @State private var accessToken: String?

  var body: some View {
    VStack {
      if let token = accessToken {

        // すでにログイン済み → イベント一覧を表示
        if viewModel.isLoading {
          ProgressView("Loading events...")
        } else if let error = viewModel.errorMessage {
          Text("Error: \(error)")
        } else {
          List(viewModel.events) { event in
            VStack(alignment: .leading) {
              Text(event.summary ?? "(No Title)")
                .font(.headline)
              if let dateTime = event.start?.dateTime {
                Text("Start: \(dateTime)")
              } else if let date = event.start?.date {
                Text("Start(終日): \(date)")
              }
            }
          }
        }
        List {
          // 新規追加への遷移例
          NavigationLink("新規イベント追加") {
            WorkoutEditView(
              accessToken: token,
              isUpdateMode: false,
              existingEventId: nil
            )
          }
        }
      } else {
        // ログイン前
        Button("Googleカレンダー情報を読み込む") {

        }
        .padding()
      }
    }
  }
}

#Preview {
  HistoryView()
}
