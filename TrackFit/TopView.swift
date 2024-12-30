//
//  TopView.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/18.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct TopView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var accessToken: String?

    var body: some View {
        NavigationStack {
            VStack {
                GoogleSignInButton() {
                    handleSignInWithGoogle()
                }
                     VStack {
                         if let token = accessToken {
                             // すでにログイン済み → イベント一覧を表示
                             if viewModel.isLoading {
                                 ProgressView("Loading events...")
                             } else if let error = viewModel.errorMessage {
                                 Text("Error: \(error)")
                             } else {
                                 List(viewModel.events) { event in
                                     VStack(alignment: .leading) {
                                         Text(event.summary ?? "(No Title)")
                                             .font(.headline)
                                         if let dateTime = event.start?.dateTime {
                                             Text("Start: \(dateTime)")
                                         } else if let date = event.start?.date {
                                             Text("Start(終日): \(date)")
                                         }
                                     }
                                 }
                             }
                         } else {
                             // ログイン前
                             Button("Google でログイン") {
                                 handleSignInWithGoogle()
                             }
                             .padding()
                         }
                     }
                     .navigationTitle("My Calendar Events")
                 }
        }
    }
    private func handleSignInWithGoogle() {
        Task {
            do {
                // 1. Info.plist に登録している CLIENT_ID を読み込み
                guard let clientID = Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as? String else {
                    print("CLIENT_ID が見つかりません")
                    return
                }

                // 2. GIDSignIn.sharedInstance の configuration を設定
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

                // 3. presenting 用の rootViewController を取得 (SceneDelegate 利用の場合)
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController
                else {
                    return
                }
                // 4. 新しいメソッドでサインイン
                let signInResult = try await GIDSignIn.sharedInstance.signIn(
                    withPresenting: rootViewController,
                    hint: nil,
                    additionalScopes: ["https://www.googleapis.com/auth/calendar.readonly"]
                )
                    // 成功時
                    let user = signInResult.user
                    let idToken = user.idToken?.tokenString   // IDトークン
                    let token = user.accessToken.tokenString // アクセストークン
                    self.accessToken = token

                    print("ログイン成功!")
                    print("idToken: \(idToken ?? "")")
                    print("accessToken: \(accessToken)")

                    /// カレンダーAPI呼び出し (async)
                    await viewModel.fetchEvents(accessToken: token)

            } catch {
                print("ログインエラー: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    TopView()
}
