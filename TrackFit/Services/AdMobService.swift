import AppTrackingTransparency
import GoogleMobileAds

/// Google AdMob広告の初期化と広告ユニットID管理を担当するサービス
///
/// ATT（App Tracking Transparency）の許可リクエスト後にAdMobを初期化する。
/// Debug/Releaseビルドに応じてテスト用・本番用の広告ユニットIDを自動切り替えする。
class AdMobService: NSObject, ObservableObject {
    static let shared = AdMobService()
    private var isInitialized = false

    private override init() {
        super.init()
    }

    /// ATTでトラッキング許可をリクエストし、完了後にAdMobを初期化する
    func requestTrackingAuthorization() {
        if isInitialized { return }

        // 少し遅延させてからリクエストを行う（アプリ起動直後の競合を避けるため）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                // 許可・拒否に関わらずAdMobを初期化（許可されていればIDFAが使われる）
                self.initializeAdMob()
            }
        }
    }

    func initializeAdMob() {
        if isInitialized { return }
        isInitialized = true

        MobileAds.shared.start { initializationStatus in
            #if DEBUG
                print("AdMob initialization completed with status: \(initializationStatus)")
            #endif
        }
    }

    func getAppID() -> String {
        guard
            let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier")
                as? String
        else {
            #if DEBUG
                print("Error: AdMob App ID not found in Info.plist")
            #endif
            fatalError("AdMob App ID not found in Info.plist")
        }
        return appID
    }

    func getTestAdUnitID() -> String {
        guard
            let testID = Bundle.main.object(forInfoDictionaryKey: "ADMOB_BANNER_UNIT_ID_TEST")
                as? String
        else {
            #if DEBUG
                print("Warning: Test AdUnit ID not found in Info.plist, using fallback")
            #endif
            // フォールバック用のテスト専用広告ユニットID
            return "ca-app-pub-3940256099942544/2435281174"
        }
        return testID
    }

    func getProductionAdUnitID() -> String {
        guard
            let prodID = Bundle.main.object(forInfoDictionaryKey: "ADMOB_BANNER_UNIT_ID_PROD")
                as? String
        else {
            #if DEBUG
                print("Error: Production AdUnit ID not found in Info.plist")
            #endif
            fatalError("Production AdUnit ID must be configured in Secrets.xcconfig")
        }
        return prodID
    }

    func getCurrentAdUnitID() -> String {
        #if DEBUG
            return getTestAdUnitID()
        #else
            return getProductionAdUnitID()
        #endif
    }
}
