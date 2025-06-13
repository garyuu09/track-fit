//
//  TrackFitApp.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/17.
//

import SwiftData
import SwiftUI

@main
struct TrackFitApp: App {
    @AppStorage("displayMode") var displayMode: DisplayMode = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(
                    displayMode == .system ? nil : (displayMode == .dark ? .dark : .light)
                )
                .modelContainer(for: [DailyWorkout.self, Exercise.self])
        }
    }
}
