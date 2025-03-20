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

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("外部連携")) {
                    HStack {
                        Image("google_calendar_logo") // GoogleカレンダーのロゴをAssetに追加
                            .resizable()
                            .frame(width: 24, height: 24)

                        Text("Googleカレンダー")

                        Spacer()

                        if isGoogleCalendarLinked, let email = linkedAccountEmail {
                            Text("連携済み")
                                .foregroundStyle(.green)
                                .font(.subheadline)

                            VStack(alignment: .trailing) {
                                Text(email)
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Button("連携解除") {
                                    unlinkGoogleCalendar()
                                }
                                .font(.caption)
                                .foregroundStyle(.red)
                            }
                        } else {
                            Button("連携する") {
                                linkGoogleCalendar()
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
        }
    }

    // Googleカレンダー連携状態を読み込み
    func loadLinkedStatus() {
        // TODO: 連携状態を読み込むロジックをここに実装
        // isGoogleCalendarLinked = true or false
        // linkedAccountEmail = "user@gmail.com"
    }

    // Googleカレンダーとの連携処理
    func linkGoogleCalendar() {
        // TODO: Google OAuth認証フローを開始する
        // 認証成功後に状態を更新する
        self.isGoogleCalendarLinked = true
        self.linkedAccountEmail = "user@gmail.com" // 実際の連携時はOAuth結果から取得
    }

    // Googleカレンダーとの連携解除処理
    func unlinkGoogleCalendar() {
        // TODO: Googleカレンダーとの連携解除処理を実行する
        self.isGoogleCalendarLinked = false
        self.linkedAccountEmail = nil
    }
}
#Preview {
    SettingView()
}
