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
            print("Status Code:", httpResponse.statusCode)
            throw URLError(.badServerResponse)
        }
        print("Response body:", String(data: data, encoding: .utf8) ?? "N/A")

        // JSONデコード
        let decoded = try JSONDecoder().decode(EventsResponse.self, from: data)
        return decoded.items
    }

    /// Google Calendar へ新規イベントを追加 (POST)
    /// - Returns: 作成されたイベントの eventId
    static func createWorkoutEvent(
        accessToken: String,
        workout: DailyWorkout
    ) async throws -> String {

        // 1) イベント開始・終了時刻をISO8601文字列に変換 (例: 1時間の枠を確保)
        //   ここでは簡易的に「開始=ユーザー選択のDate」「終了=+1時間」として例示します
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)  // UTC
        let startString = dateFormatter.string(from: workout.startDate)
        let endString = dateFormatter.string(from: workout.endDate)

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
        workout: DailyWorkout
    ) async throws {
        // 1) イベント開始・終了時刻をISO8601文字列に変換 (例: 1時間の枠を確保)
        //   ここでは簡易的に「開始=ユーザー選択のDate」「終了=+1時間」として例示します
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)  // UTC
        let startString = dateFormatter.string(from: workout.startDate)
        let endString = dateFormatter.string(from: workout.endDate)
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
                print("CLIENT_ID が見つかりません")
                return false
            }

            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

            guard
                let windowScene = await UIApplication.shared.connectedScenes.first
                    as? UIWindowScene,
                let rootViewController = await windowScene.windows.first?.rootViewController
            else {
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
            let token = user.accessToken.tokenString
            let email = user.profile?.email ?? "user@gmail.com"

            UserDefaults.standard.set(token, forKey: "GoogleAccessToken")
            UserDefaults.standard.set(email, forKey: "GoogleEmail")

            print("ログイン成功!")
            print("idToken: \(idToken ?? "")")
            print("accessToken: \(token)")
            UserDefaults.standard.set(true, forKey: "isCalendarLinked")
            return true

        } catch {
            print("ログインエラー: \(error.localizedDescription)")
            return false
        }
    }

    // Googleカレンダーとの連携解除処理
    static func unlinkGoogleCalendar() {
        // Googleサインアウト処理
        GIDSignIn.sharedInstance.signOut()

        // 保存しているトークンやメールアドレスを削除
        UserDefaults.standard.removeObject(forKey: "GoogleAccessToken")
        UserDefaults.standard.removeObject(forKey: "GoogleEmail")
    }
}
