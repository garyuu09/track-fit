//
//  TopView.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/18.
//

import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

struct TopView: View {
  @State private var accessToken: String?

  var body: some View {
    VStack {
      GoogleSignInButton {
        handleSignInWithGoogle()
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
          additionalScopes: [
            "https://www.googleapis.com/auth/calendar.readonly",
            "https://www.googleapis.com/auth/calendar.events",
          ]
        )
        // 成功時
        let user = signInResult.user
        let idToken = user.idToken?.tokenString  // IDトークン
        let token = user.accessToken.tokenString  // アクセストークン
        self.accessToken = token

        print("ログイン成功!")
        print("idToken: \(idToken ?? "")")
        print("accessToken: \(accessToken)")
        // TODO: キーチェーンに保存する
        tempAccessToken = accessToken ?? ""

      } catch {
        print("ログインエラー: \(error.localizedDescription)")
      }
    }
  }
}

#Preview {
  TopView()
}
