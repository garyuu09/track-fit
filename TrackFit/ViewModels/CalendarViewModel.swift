//
//  CalendarViewModel.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/28.
//

import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // カレンダーイベントを取得する (async/await)
    func fetchEvents(accessToken: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let items = try await GoogleCalendarAPI.fetchEvents(accessToken: accessToken)
            self.events = items
        } catch {
            self.errorMessage = "取得エラー: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
