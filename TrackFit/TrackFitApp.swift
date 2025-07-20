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

    init() {
        // AdMobの初期化
        AdMobService.shared.initializeAdMob()
    }

    var body: some Scene {
        WindowGroup {
            LaunchScreen()
                .tint(Color.trackFitThemeColor)
                .preferredColorScheme(
                    displayMode == .system ? nil : (displayMode == .dark ? .dark : .light)
                )
                .modelContainer(for: [DailyWorkout.self, Exercise.self])
        }
    }
}
