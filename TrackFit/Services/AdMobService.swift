import Foundation
import GoogleMobileAds

class AdMobService: NSObject, ObservableObject {
    static let shared = AdMobService()

    private override init() {
        super.init()
    }

    func initializeAdMob() {
        MobileAds.shared.start { initializationStatus in
            print("AdMob initialization completed with status: \(initializationStatus)")
        }
    }

    func getAppID() -> String {
        guard
            let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier")
                as? String
        else {
            print("Error: AdMob App ID not found in Info.plist")
            fatalError("AdMob App ID not found in Info.plist")
        }
        return appID
    }

    func getTestAdUnitID() -> String {
        guard
            let testID = Bundle.main.object(forInfoDictionaryKey: "ADMOB_BANNER_UNIT_ID_TEST")
                as? String
        else {
            print("Warning: Test AdUnit ID not found in Info.plist, using fallback")
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
            print("Warning: Production AdUnit ID not found in Info.plist, using fallback")
            // フォールバック用
            return "ca-app-pub-3386119641089297/7299235005"
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
