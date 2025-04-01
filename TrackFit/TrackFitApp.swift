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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: DailyWorkout.self)
        }
    }
}
