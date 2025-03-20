//
//  SettingView.swift
//  TrackFit
//
//  Created by Ryuga on 2025/03/08.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct SettingView: View {
    @State private var isGoogleCalendarLinked: Bool = false
    @State private var linkedAccountEmail: String? = nil
    @State private var accessToken: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("外部連携")) {
                    HStack {
                        Text("Googleカレンダー")
                        Spacer()
                        if isGoogleCalendarLinked, let email = linkedAccountEmail {
                            Text("連携済み")
                                .foregroundColor(.green)
                                .font(.subheadline)
                            VStack(alignment: .trailing) {
                                Text(email)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Button("連携解除") {
                                    unlinkGoogleCalendar()
                                }
                                .font(.caption)
                                .foregroundColor(.red)
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

    // 連携状態を読み込み（例：UserDefaultsまたはキーチェーンから）
    func loadLinkedStatus() {
        // ※ここではUserDefaultsを使った例です。実際はセキュアなキーチェーンへの保存を検討してください。
        if let savedToken = UserDefaults.standard.string(forKey: "GoogleAccessToken"),
           let savedEmail = UserDefaults.standard.string(forKey: "GoogleEmail") {
            self.accessToken = savedToken
            self.isGoogleCalendarLinked = true
            self.linkedAccountEmail = savedEmail
        } else {
            self.isGoogleCalendarLinked = false
            self.linkedAccountEmail = nil
        }
    }

    // Googleカレンダーとの連携処理（OAuth認証フローを実行）
    func linkGoogleCalendar() {
        Task {
            do {
                // 1. Info.plist に登録されている CLIENT_ID を取得
                guard let clientID = Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as? String else {
                    print("CLIENT_ID が見つかりません")
                    return
                }

                // 2. GIDSignInのconfigurationを設定
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

                // 3. presenting用のrootViewControllerを取得（SceneDelegate利用の場合）
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController
                else {
                    return
                }

                // 4. Googleサインイン（OAuth認証）を実施
                let signInResult = try await GIDSignIn.sharedInstance.signIn(
                    withPresenting: rootViewController,
                    hint: nil,
                    additionalScopes: [
                        "https://www.googleapis.com/auth/calendar.readonly",
                        "https://www.googleapis.com/auth/calendar.events"
                    ]
                )

                let user = signInResult.user
                let idToken = user.idToken?.tokenString
                let token = user.accessToken.tokenString
                self.accessToken = token

                // ユーザーのメールアドレスを取得
                let email = user.profile?.email ?? "user@gmail.com"

                // メインスレッドで連携状態を更新
                await MainActor.run {
                    self.isGoogleCalendarLinked = true
                    self.linkedAccountEmail = email
                }

                // UserDefaultsにアクセストークンやメールを保存する
                UserDefaults.standard.set(token, forKey: "GoogleAccessToken")
                UserDefaults.standard.set(email, forKey: "GoogleEmail")

                print("ログイン成功!")
                print("idToken: \(idToken ?? "")")
                print("accessToken: \(token)")

            } catch {
                print("ログインエラー: \(error.localizedDescription)")
            }
        }
    }

    // Googleカレンダーとの連携解除処理
    func unlinkGoogleCalendar() {
        // Googleサインアウト処理
        GIDSignIn.sharedInstance.signOut()
        self.isGoogleCalendarLinked = false
        self.linkedAccountEmail = nil
        self.accessToken = nil

        // 保存しているトークンやメールアドレスを削除
        UserDefaults.standard.removeObject(forKey: "GoogleAccessToken")
        UserDefaults.standard.removeObject(forKey: "GoogleEmail")
    }
}
#Preview {
    SettingView()
}
