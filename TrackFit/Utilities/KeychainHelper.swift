//
//  KeychainHelper.swift
//  TrackFit
//
//  Created by Claude Code on 2025/01/01.
//

import Foundation
import Security

/// Keychain操作のヘルパークラス
/// センシティブな情報（トークンなど）を安全に保存・取得する
class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    /// データをKeychainに保存
    /// - Parameters:
    ///   - data: 保存するデータ
    ///   - key: 保存キー
    /// - Returns: 保存成功時はtrue
    func save(_ data: Data, forKey key: String) -> Bool {
        // 既存データがある場合は削除
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.ribereo.minami.TrackFit",
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            #if DEBUG
                print("Keychain保存エラー: \(status) for key: \(key)")
            #endif
        }
        return status == errSecSuccess
    }

    /// 文字列をKeychainに保存
    /// - Parameters:
    ///   - string: 保存する文字列
    ///   - key: 保存キー
    /// - Returns: 保存成功時はtrue
    func save(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, forKey: key)
    }

    /// Keychainからデータを取得
    /// - Parameter key: 取得キー
    /// - Returns: 取得したデータ。見つからない場合はnil
    func load(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.ribereo.minami.TrackFit",
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            return dataTypeRef as? Data
        } else if status != errSecItemNotFound {
            #if DEBUG
                print("Keychain取得エラー: \(status) for key: \(key)")
            #endif
        }
        return nil
    }

    /// Keychainから文字列を取得
    /// - Parameter key: 取得キー
    /// - Returns: 取得した文字列。見つからない場合はnil
    func loadString(forKey key: String) -> String? {
        guard let data = load(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Keychainからデータを削除
    /// - Parameter key: 削除キー
    /// - Returns: 削除成功時はtrue
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.ribereo.minami.TrackFit",
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            #if DEBUG
                print("Keychain削除エラー: \(status) for key: \(key)")
            #endif
        }
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// 指定されたキーのデータが存在するかチェック
    /// - Parameter key: チェックキー
    /// - Returns: データが存在する場合はtrue
    func exists(forKey key: String) -> Bool {
        return load(forKey: key) != nil
    }
}

// MARK: - Google認証関連のキー定数
extension KeychainHelper {
    enum GoogleTokenKeys {
        static let accessToken = "GoogleAccessToken"
        static let refreshToken = "GoogleRefreshToken"
        static let email = "GoogleEmail"
        static let tokenExpiryDate = "GoogleTokenExpiryDate"
    }
}
