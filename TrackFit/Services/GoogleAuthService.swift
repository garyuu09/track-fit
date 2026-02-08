//
//  GoogleAuthService.swift
//  TrackFit
//
//  Refactored from GoogleCalendarAPI.swift
//

import Foundation
import GoogleSignIn

/// Google OAuth認証とトークン管理を担当するサービス
///
/// サインイン・サインアウト、トークンのリフレッシュ、連携状態の確認を行う。
/// 認証情報は`KeychainHelper`を通じてKeychainに安全に保存される。
struct GoogleAuthService {

    // MARK: - 連携・解除

    /// Googleカレンダーとの連携処理（OAuth認証フローを実行）
    static func linkGoogleCalendar() async throws -> Bool {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as? String else {
            #if DEBUG
                print("CLIENT_ID が見つかりません")
            #endif
            return false
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        let rootViewController = await MainActor.run { () -> UIViewController? in
            guard
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first,
                let rootViewController = window.rootViewController
            else {
                return nil
            }
            return rootViewController
        }

        guard let rootViewController = rootViewController else {
            return false
        }

        let signInResult = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: [
                "https://www.googleapis.com/auth/calendar.readonly",
                "https://www.googleapis.com/auth/calendar.events",
            ]
        )

        let user = signInResult.user
        let accessToken = user.accessToken.tokenString
        let refreshToken = user.refreshToken.tokenString
        let email = user.profile?.email ?? "user@gmail.com"
        let expiryDate = user.accessToken.expirationDate

        let keychain = KeychainHelper.shared
        _ = keychain.save(accessToken, forKey: KeychainHelper.GoogleTokenKeys.accessToken)
        _ = keychain.save(email, forKey: KeychainHelper.GoogleTokenKeys.email)
        _ = keychain.save(refreshToken, forKey: KeychainHelper.GoogleTokenKeys.refreshToken)

        if let expiryDate = expiryDate {
            let expiryTimestamp = String(expiryDate.timeIntervalSince1970)
            _ = keychain.save(
                expiryTimestamp, forKey: KeychainHelper.GoogleTokenKeys.tokenExpiryDate)
        }

        #if DEBUG
            print("ログイン成功!")
            print("accessToken: 取得済み")
            print("refreshToken: 保存済み")
        #endif
        UserDefaults.standard.set(true, forKey: "isCalendarLinked")
        return true
    }

    /// Googleカレンダーとの連携解除処理
    static func unlinkGoogleCalendar() {
        GIDSignIn.sharedInstance.signOut()

        let keychain = KeychainHelper.shared
        _ = keychain.delete(forKey: KeychainHelper.GoogleTokenKeys.accessToken)
        _ = keychain.delete(forKey: KeychainHelper.GoogleTokenKeys.refreshToken)
        _ = keychain.delete(forKey: KeychainHelper.GoogleTokenKeys.email)
        _ = keychain.delete(forKey: KeychainHelper.GoogleTokenKeys.tokenExpiryDate)

        #if DEBUG
            print("Google認証情報をすべて削除しました")
        #endif
    }

    // MARK: - トークン管理

    /// リフレッシュトークンを使用してアクセストークンを更新
    static func refreshAccessToken() async throws -> String {
        do {
            let result = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            let newAccessToken = result.accessToken.tokenString
            let newExpiryDate = result.accessToken.expirationDate

            let keychain = KeychainHelper.shared
            _ = keychain.save(newAccessToken, forKey: KeychainHelper.GoogleTokenKeys.accessToken)

            if let expiryDate = newExpiryDate {
                let expiryTimestamp = String(expiryDate.timeIntervalSince1970)
                _ = keychain.save(
                    expiryTimestamp, forKey: KeychainHelper.GoogleTokenKeys.tokenExpiryDate)
            }

            #if DEBUG
                print("アクセストークンを更新しました")
            #endif
            return newAccessToken
        } catch {
            #if DEBUG
                print("トークン更新エラー: \(error.localizedDescription)")
            #endif
            throw CalendarAPIError.refreshFailed(underlying: error)
        }
    }

    /// アクセストークンの有効性チェック（期限チェック含む）
    static func validateAccessToken(accessToken: String? = nil) async -> Bool {
        let token =
            accessToken
            ?? KeychainHelper.shared.loadString(forKey: KeychainHelper.GoogleTokenKeys.accessToken)

        guard let token = token else {
            #if DEBUG
                print("アクセストークンが見つかりません")
            #endif
            return false
        }

        if isTokenExpired() {
            #if DEBUG
                print("アクセストークンの期限が切れています")
            #endif
            return false
        }

        guard let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary")
        else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (200..<300).contains(httpResponse.statusCode)
            }
        } catch {
            #if DEBUG
                print("トークン検証エラー: \(error.localizedDescription)")
            #endif
        }
        return false
    }

    /// トークンの期限切れチェック
    static func isTokenExpired() -> Bool {
        guard
            let expiryTimestampString = KeychainHelper.shared.loadString(
                forKey: KeychainHelper.GoogleTokenKeys.tokenExpiryDate),
            let expiryTimestamp = Double(expiryTimestampString)
        else {
            return true
        }

        let expiryDate = Date(timeIntervalSince1970: expiryTimestamp)
        let bufferTime: TimeInterval = 5 * 60
        return Date().addingTimeInterval(bufferTime) >= expiryDate
    }

    // MARK: - 連携状態チェック

    /// 連携状態の自動チェックと更新
    static func checkAndUpdateLinkingStatus() async {
        guard
            let accessToken = KeychainHelper.shared.loadString(
                forKey: KeychainHelper.GoogleTokenKeys.accessToken),
            !accessToken.isEmpty
        else {
            await MainActor.run {
                UserDefaults.standard.set(false, forKey: "isCalendarLinked")
                UserDefaults.standard.set(true, forKey: "showIntegrationBanner")
            }
            return
        }

        let isValid = await validateAccessToken(accessToken: accessToken)
        await MainActor.run {
            if !isValid {
                Task {
                    do {
                        _ = try await refreshAccessToken()
                        UserDefaults.standard.set(true, forKey: "isCalendarLinked")
                        #if DEBUG
                            print("アクセストークンを更新しました")
                        #endif
                    } catch {
                        unlinkGoogleCalendar()
                        UserDefaults.standard.set(false, forKey: "isCalendarLinked")
                        UserDefaults.standard.set(true, forKey: "showIntegrationBanner")
                        #if DEBUG
                            print(
                                "トークン更新に失敗したため連携を解除しました: \(error.localizedDescription)")
                        #endif
                    }
                }
            } else {
                UserDefaults.standard.set(true, forKey: "isCalendarLinked")
            }
        }
    }
}
