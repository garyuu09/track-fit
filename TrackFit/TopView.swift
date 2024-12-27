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
    var body: some View {
        NavigationStack {
            VStack {
                GoogleSignInButton() {
                    handleSignInWithGoogle()
                }
                Text("TopView")
            }
            .navigationTitle("Summary")
        }
    }
    private func handleSignInWithGoogle() {
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
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        ) { signInResult, error in
            if let error = error {
                // エラーハンドリング
                print("ログインエラー: \(error.localizedDescription)")
                return
            }

            // 成功時
            guard let result = signInResult else { return }
            let user = result.user
            let idToken = user.idToken?.tokenString   // IDトークン
            let accessToken = user.accessToken.tokenString // アクセストークン

            print("ログイン成功!")
            print("idToken: \(idToken ?? "")")
            print("accessToken: \(accessToken)")
        }
    }
}

#Preview {
    TopView()
}
