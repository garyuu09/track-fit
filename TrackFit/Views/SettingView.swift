//
//  SettingView.swift
//  TrackFit
//
//  Created by Ryuga on 2025/03/08.
//

import SwiftUI

struct SettingView: View {
    @State private var isGoogleCalendarLinked: Bool = false
    @State private var linkedAccountEmail: String? = nil
    @State private var accessToken: String? = nil
    @State private var isShowCalendarIntegration: Bool = false
    @State private var showIntegrationBanner: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("外部連携")) {
                    HStack {
                        Text("Googleカレンダー")
                        Spacer()
                        if isGoogleCalendarLinked, let email = linkedAccountEmail {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Googleカレンダーと連携中")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)

                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Button("連携を解除") {
                                        GoogleCalendarAPI.unlinkGoogleCalendar()
                                        UserDefaults.standard.set(false, forKey: "isCalendarLinked")
                                        isGoogleCalendarLinked = false
                                        UserDefaults.standard.set(
                                            true, forKey: "showIntegrationBanner")
                                        linkedAccountEmail = nil
                                        accessToken = nil
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                            }
                        } else {
                            Button("連携する") {
                                isShowCalendarIntegration = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                Section("App Settings") {
                    Text("アプリの設定")
                    Text("テーマカラー")
                }
                Section("Support") {
                    Text("サポート")
                    Text("問い合わせ先")
                }
                Section("About TrackFit") {
                    Text("Privacy Policy")
                    Text("TrackFitをレビューする")

                }
            }
            .navigationTitle("設定")
            .onAppear {
                loadLinkedStatus()
            }
            // モーダルで連携画面を表示
            .sheet(isPresented: $isShowCalendarIntegration) {
                GoogleCalendarIntegrationView(
                    onFinish: { didLink in
                        if didLink {
                            UserDefaults.standard.set(true, forKey: "isCalendarLinked")
                            accessToken = UserDefaults.standard.string(
                                forKey: "GoogleAccessToken")
                            linkedAccountEmail = UserDefaults.standard.string(
                                forKey: "GoogleEmail")
                        }
                        isShowCalendarIntegration = false
                    },
                    showIntegrationBanner: $showIntegrationBanner
                )
            }
        }
    }

    // 連携状態を読み込み（例：UserDefaultsまたはキーチェーンから）
    func loadLinkedStatus() {
        // ※ここではUserDefaultsを使った例です。実際はセキュアなキーチェーンへの保存を検討してください。
        if let savedToken = UserDefaults.standard.string(forKey: "GoogleAccessToken"),
            let savedEmail = UserDefaults.standard.string(forKey: "GoogleEmail")
        {
            self.accessToken = savedToken
            self.isGoogleCalendarLinked = true
            self.linkedAccountEmail = savedEmail
        } else {
            self.isGoogleCalendarLinked = false
            self.linkedAccountEmail = nil
        }
    }
}
#Preview {
    SettingView()
}
