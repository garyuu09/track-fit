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
    @State var selection = 0
    @State private var accessToken: String?

    var body: some View {
        TabView(selection: $selection) {
            WorkoutRecordView()
                .tabItem {
                    Label("トレーニング記録", systemImage: "timer")
                }
                .tag(0)

            SettingView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
