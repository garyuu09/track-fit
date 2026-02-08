//
//  ContentView.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/17.
//

import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selection: TabSelection = .home
    @State private var isSearchPresented = false
    @State private var accessToken: String?

    enum TabSelection {
        case home
        case workout
        case history
        case setting
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selection) {
                Tab("ホーム", systemImage: "house", value: .home) {
                    HomeView()
                }
                .accessibilityIdentifier("homeTab")

                Tab("トレーニング記録", systemImage: "timer", value: .workout) {
                    WorkoutRecordView()
                }
                .accessibilityIdentifier("workoutTab")

                Tab(value: .history, role: .search) {
                    TrainingHistoryView(isSearchPresented: $isSearchPresented)
                }
                .accessibilityIdentifier("historyTab")

                Tab("設定", systemImage: "gearshape", value: .setting) {
                    SettingView()
                }
                .accessibilityIdentifier("settingTab")
            }
            .accessibilityIdentifier("mainTabView")
        }
    }
}

#Preview {
    ContentView()
}
