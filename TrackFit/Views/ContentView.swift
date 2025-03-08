//
//  ContentView.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/17.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    // タブの選択項目を保持する
    @StateObject private var viewModel = CalendarViewModel()
    @State var selection = 1
    @State private var accessToken: String?

    var body: some View {

        TabView(selection: $selection) {
            WorkoutRecordView()
                .tabItem {
                    Label("トレーニング記録", systemImage: "timer")
                }
                .tag(1)

            SettingView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }

            //　TODO: 3/31リリース後にタブを追加して、機能開発する。
//            HistoryView()
//                .tabItem {
//                    Label("カレンダー", systemImage: "calendar")
//                }
//                .tag(2)
            //　TODO: 3/31リリース後にタブを追加して、機能開発する。
//            TrendView()
//                .tabItem {
//                    Label("トレンド", systemImage: "chart.bar.fill")
//                }
//                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}
