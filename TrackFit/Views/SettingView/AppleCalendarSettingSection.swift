//
//  AppleCalendarSettingSection.swift
//  TrackFit
//

import EventKit
import SwiftUI

/// Appleカレンダー連携設定のセクションビュー
struct AppleCalendarSettingSection: View {
    @AppStorage("isAppleCalendarLinked") private var isAppleCalendarLinked: Bool = false
    @AppStorage("appleCalendarIdentifier") private var appleCalendarIdentifier: String = ""
    @State private var writableCalendars: [EKCalendar] = []
    @State private var showPermissionAlert = false

    var body: some View {
        HStack(alignment: .top) {
            Text("Appleカレンダー")
            Spacer()
            if isAppleCalendarLinked {
                linkedView
            } else {
                Button("連携する") {
                    Task { await requestAndLink() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            if isAppleCalendarLinked {
                refreshPermissionState()
                loadCalendars()
            }
        }
        .alert("カレンダーへのアクセスが必要です", isPresented: $showPermissionAlert) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("設定アプリからTrackFitのカレンダーアクセスを許可してください。")
        }
    }

    // MARK: - 連携中の表示
    private var linkedView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Appleカレンダーと連携中")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)

                    // カレンダー選択Picker
                    if !writableCalendars.isEmpty {
                        Picker("カレンダー", selection: $appleCalendarIdentifier) {
                            ForEach(writableCalendars, id: \.calendarIdentifier) { cal in
                                HStack {
                                    Circle()
                                        .fill(Color(cgColor: cal.cgColor))
                                        .frame(width: 12, height: 12)
                                    Text(cal.title)
                                }
                                .tag(cal.calendarIdentifier)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Button("連携を解除") {
                        isAppleCalendarLinked = false
                        appleCalendarIdentifier = ""
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func requestAndLink() async {
        do {
            let granted = try await AppleCalendarService.requestAccess()
            await MainActor.run {
                if granted {
                    isAppleCalendarLinked = true
                    loadCalendars()
                    if appleCalendarIdentifier.isEmpty,
                        let defaultCal = AppleCalendarService.defaultCalendar()
                    {
                        appleCalendarIdentifier = defaultCal.calendarIdentifier
                    }
                } else {
                    showPermissionAlert = true
                }
            }
        } catch {
            await MainActor.run {
                showPermissionAlert = true
            }
        }
    }

    private func loadCalendars() {
        writableCalendars = AppleCalendarService.writableCalendars()
    }

    /// 権限が後から取り消されていないかチェック
    private func refreshPermissionState() {
        if !AppleCalendarService.hasFullAccess {
            isAppleCalendarLinked = false
            appleCalendarIdentifier = ""
        }
    }
}
