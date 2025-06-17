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
            LaunchScreen()
                .tint(Color(red: 242 / 255, green: 137 / 255, blue: 58 / 255))
                .preferredColorScheme(
                    displayMode == .system ? nil : (displayMode == .dark ? .dark : .light)
                )
                .modelContainer(for: [DailyWorkout.self, Exercise.self])
        }
    }
}
