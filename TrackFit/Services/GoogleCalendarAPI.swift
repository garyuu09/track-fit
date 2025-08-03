//
//  GoogleCalendarAPI.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/28.
//
import Foundation
import GoogleSignIn
import GoogleSignInSwift

struct GoogleCalendarAPI {
    // APIのレスポンス全体
    struct EventsResponse: Codable {
        let items: [CalendarEvent]
    }

    static func fetchEvents(accessToken: String) async throws -> [CalendarEvent] {
        return try await makeAPICallWithAutoRefresh { token in
            return try await _fetchEvents(accessToken: token)
        }
    }

    private static func _fetchEvents(accessToken: String) async throws -> [CalendarEvent] {
        // プライマリカレンダーのイベントを取得する
        guard
            let url = URL(
                string:
                    "https://www.googleapis.com/calendar/v3/calendars/primary/events?maxResults=20&orderBy=startTime&singleEvents=true&orderBy=startTime&timeMin=2024-01-01T00%3A00%3A00Z&timeMax=2024-02-01T00%3A00%3A00Z"
            )
        else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // async/await で通信
        let (data, response) = try await URLSession.shared.data(for: request)

        // ステータスコードチェック (例)
        if let httpResponse = response as? HTTPURLResponse,
            !(200..<300).contains(httpResponse.statusCode)
        {
            #if DEBUG
                print("Status Code:", httpResponse.statusCode)
            #endif
            throw URLError(.badServerResponse)
        }
        #if DEBUG
            print("Response body:", String(data: data, encoding: .utf8) ?? "N/A")
        #endif

        // JSONデコード
        let decoded = try JSONDecoder().decode(EventsResponse.self, from: data)
        return decoded.items
    }

    /// Google Calendar へ新規イベントを追加 (POST)
    /// - Returns: 作成されたイベントの eventId
    static func createWorkoutEvent(
        accessToken: String,
        workout: DailyWorkout,
        colorId: String = "4"  // デフォルトは「みかん」
    ) async throws -> String {
        return try await makeAPICallWithAutoRefresh { token in
            return try await _createWorkoutEvent(
                accessToken: token, workout: workout, colorId: colorId)
        }
    }

    private static func _createWorkoutEvent(
        accessToken: String,
        workout: DailyWorkout,
        colorId: String = "4"
    ) async throws -> String {

        // 1) イベント開始・終了時刻をISO8601文字列に変換
        let startString = DateHelper.iso8601String(from: workout.startDate)
        let endString = DateHelper.iso8601String(from: workout.endDate)

        // 2) イベントの要素をJSONに組み立て
        // 各レコードの詳細を文字列に変換し、改行で結合
        let descriptionText = workout.records.map { record in
            """
            種目: \(record.exerciseName)
            重量: \(record.weight) kg
            セット数: \(record.sets)
            回数: \(record.reps)
            """
        }.joined(separator: "\n\n")

        // イベント作成用のリクエストボディにまとめる
        //   - summary: イベントのタイトル
        //   - description: メモ欄 (種目・重量・セット数・回数などをここに記載)
        //   - start/end: ISO8601形式の日付
        let newEventRequestBody: [String: Any] = [
            "summary": "トレーニング",
            "description": descriptionText,
            "start": [
                "dateTime": startString,
                "timeZone": "UTC",
            ],
            "end": [
                "dateTime": endString,
                "timeZone": "UTC",
            ],
            "colorId": colorId,
        ]

        // 3) JSONエンコード
        let requestData = try JSONSerialization.data(
            withJSONObject: newEventRequestBody, options: [])

        // 4) URLRequest 作成
        guard
            let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")
        else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData

        // 5) URLSession でリクエスト (async/await)
        let (data, response) = try await URLSession.shared.data(for: request)

        // 6) ステータスコードチェック
        if let httpResponse = response as? HTTPURLResponse,
            !(200..<300).contains(httpResponse.statusCode)
        {
            // 失敗時のレスポンスを表示（デバッグ用）
            let bodyString = String(data: data, encoding: .utf8) ?? "N/A"
            throw NSError(
                domain: "GoogleCalendarAPI", code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "イベント作成失敗 (\(httpResponse.statusCode))\n\(bodyString)"
                ])
        }

        // 7) イベントIDをレスポンスから取得
        struct CreateEventResponse: Decodable {
            let id: String
        }
        let decoded = try JSONDecoder().decode(CreateEventResponse.self, from: data)

        return decoded.id
    }

    /// 既存イベントを更新 (PATCH)
    /// - Parameter eventId: 更新対象のイベントID
    static func updateWorkoutEvent(
        accessToken: String,
        eventId: String,
        workout: DailyWorkout,
        colorId: String = "4"  // デフォルトは「みかん」
    ) async throws {
        return try await makeAPICallWithAutoRefresh { token in
            return try await _updateWorkoutEvent(
                accessToken: token, eventId: eventId, workout: workout, colorId: colorId)
        }
    }

    private static func _updateWorkoutEvent(
        accessToken: String,
        eventId: String,
        workout: DailyWorkout,
        colorId: String = "4"
    ) async throws {
        // 1) イベント開始・終了時刻をISO8601文字列に変換
        let startString = DateHelper.iso8601String(from: workout.startDate)
        let endString = DateHelper.iso8601String(from: workout.endDate)
        // 2) イベントの要素をJSONに組み立て
        // 各レコードの詳細を文字列に変換し、改行で結合
        let descriptionText = workout.records.map { record in
            """
            種目: \(record.exerciseName)
            重量: \(record.weight) kg
            セット数: \(record.sets)
            回数: \(record.reps)
            """
        }.joined(separator: "\n\n")

        // 2) 更新内容をJSONに組み立て
        let updateEventRequestBody: [String: Any] = [
            "summary": "トレーニング",
            "description": descriptionText,
            "start": [
                "dateTime": startString,
                "timeZone": "UTC",
            ],
            "end": [
                "dateTime": endString,
                "timeZone": "UTC",
            ],
            "colorId": colorId,
        ]

        let requestData = try JSONSerialization.data(
            withJSONObject: updateEventRequestBody, options: [])

        // 3) PATCHエンドポイント
        //    - PUT でもOKですが、PATCHのほうが一部更新に向いています (Google Calendar API ドキュメントより)
        guard
            let url = URL(
                string: "https://www.googleapis.com/calendar/v3/calendars/primary/events/\(eventId)"
            )
        else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
            !(200..<300).contains(httpResponse.statusCode)
        {
            let bodyString = String(data: data, encoding: .utf8) ?? "N/A"
            throw NSError(
                domain: "GoogleCalendarAPI", code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "イベント更新失敗 (\(httpResponse.statusCode))\n\(bodyString)"
                ])
        }
    }

    // Googleカレンダーとの連携処理（OAuth認証フローを実行）
    static func linkGoogleCalendar() async throws -> Bool {
        do {
            guard
                let clientID = Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as? String
            else {
                #if DEBUG
                    print("CLIENT_ID が見つかりません")
                #endif
                return false
            }

            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

            let rootViewController = await MainActor.run { () -> UIViewController? in
                guard
                    let windowScene = UIApplication.shared.connectedScenes.first
                        as? UIWindowScene,
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
            let idToken = user.idToken?.tokenString
            let accessToken = user.accessToken.tokenString
            let refreshToken = user.refreshToken.tokenString
            let email = user.profile?.email ?? "user@gmail.com"
            let expiryDate = user.accessToken.expirationDate

            // Keychainに安全に保存
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
                print("idToken: \(idToken != nil ? "取得済み" : "なし")")
                print("accessToken: 取得済み")
                print("refreshToken: 保存済み")
            #endif
            UserDefaults.standard.set(true, forKey: "isCalendarLinked")
            return true

        } catch {
            #if DEBUG
                print("ログインエラー: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    // アクセストークンの有効性チェック（期限チェック含む）
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

        // 期限チェック
        if isTokenExpired() {
            #if DEBUG
                print("アクセストークンの期限が切れています")
            #endif
            return false
        }

        guard
            let url = URL(
                string: "https://www.googleapis.com/calendar/v3/calendars/primary"
            )
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

    // トークンの期限切れチェック
    private static func isTokenExpired() -> Bool {
        guard
            let expiryTimestampString = KeychainHelper.shared.loadString(
                forKey: KeychainHelper.GoogleTokenKeys.tokenExpiryDate),
            let expiryTimestamp = Double(expiryTimestampString)
        else {
            // 期限情報がない場合は期限切れとして扱う
            return true
        }

        let expiryDate = Date(timeIntervalSince1970: expiryTimestamp)
        let bufferTime: TimeInterval = 5 * 60  // 5分のバッファ
        return Date().addingTimeInterval(bufferTime) >= expiryDate
    }

    // 連携状態の自動チェックと更新
    static func checkAndUpdateLinkingStatus() async {
        guard
            let accessToken = KeychainHelper.shared.loadString(
                forKey: KeychainHelper.GoogleTokenKeys.accessToken),
            !accessToken.isEmpty
        else {
            // トークンが存在しない場合は連携解除状態に設定
            await MainActor.run {
                UserDefaults.standard.set(false, forKey: "isCalendarLinked")
                UserDefaults.standard.set(true, forKey: "showIntegrationBanner")
            }
            return
        }

        let isValid = await validateAccessToken(accessToken: accessToken)
        await MainActor.run {
            if !isValid {
                // トークンが無効な場合はリフレッシュを試行
                Task {
                    do {
                        _ = try await refreshAccessToken()
                        UserDefaults.standard.set(true, forKey: "isCalendarLinked")
                        #if DEBUG
                            print("アクセストークンを更新しました")
                        #endif
                    } catch {
                        // リフレッシュに失敗した場合は連携解除
                        unlinkGoogleCalendar()
                        UserDefaults.standard.set(false, forKey: "isCalendarLinked")
                        UserDefaults.standard.set(true, forKey: "showIntegrationBanner")
                        #if DEBUG
                            print("トークン更新に失敗したため連携を解除しました: \(error.localizedDescription)")
                        #endif
                    }
                }
            } else {
                // トークンが有効な場合は連携状態を確認
                UserDefaults.standard.set(true, forKey: "isCalendarLinked")
            }
        }
    }

    // リフレッシュトークンを使用してアクセストークンを更新
    static func refreshAccessToken() async throws -> String {
        do {
            // GoogleSignInのrestorePreviousSignInを使用してトークンを更新
            let result = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            let newAccessToken = result.accessToken.tokenString
            let newExpiryDate = result.accessToken.expirationDate

            // 新しいトークンをKeychainに保存
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
            throw error
        }
    }

    // 自動リトライ機能付きのAPI呼び出しヘルパー
    static func makeAPICallWithAutoRefresh<T>(_ apiCall: @escaping (String) async throws -> T)
        async throws -> T
    {
        let accessToken =
            KeychainHelper.shared.loadString(forKey: KeychainHelper.GoogleTokenKeys.accessToken)
            ?? ""

        do {
            return try await apiCall(accessToken)
        } catch {
            // HTTP 401エラーまたはトークン期限切れの場合はリトライ
            if let nsError = error as NSError?, nsError.code == 401 || isTokenExpired() {
                #if DEBUG
                    print("認証エラーを検出、トークンを更新してリトライします")
                #endif
                let newToken = try await refreshAccessToken()
                return try await apiCall(newToken)
            }
            throw error
        }
    }

    // Googleカレンダーとの連携解除処理
    static func unlinkGoogleCalendar() {
        // Googleサインアウト処理
        GIDSignIn.sharedInstance.signOut()

        // Keychainから全ての認証情報を削除
        let keychain = KeychainHelper.shared
        _ = keychain.delete(forKey: KeychainHelper.GoogleTokenKeys.accessToken)
        _ = keychain.delete(forKey: KeychainHelper.GoogleTokenKeys.refreshToken)
        _ = keychain.delete(forKey: KeychainHelper.GoogleTokenKeys.email)
        _ = keychain.delete(forKey: KeychainHelper.GoogleTokenKeys.tokenExpiryDate)

        #if DEBUG
            print("Google認証情報をすべて削除しました")
        #endif
    }
}
