//
//  ContentView.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/17.
//

import SwiftUI

struct ContentView: View {
    // タブの選択項目を保持する
    @State var selection = 1
    var body: some View {

        TabView(selection: $selection) {
            TopView()
                .tabItem {
                    Label("Page1", systemImage: "1.circle")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("Page2", systemImage: "2.circle")
                }
                .tag(2)

            AnalysisView()
                .tabItem {
                    Label("Page3", systemImage: "3.circle")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}
