import GoogleMobileAds
import SwiftUI
import UIKit

struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String

    init(adUnitID: String = AdMobService.shared.getCurrentAdUnitID()) {
        self.adUnitID = adUnitID
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID

        // iOS 15以降とそれ以前での対応
        if #available(iOS 15.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first
            {
                bannerView.rootViewController = window.rootViewController
            }
        } else {
            bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        }

        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // 必要に応じて更新処理を追加
    }
}

// プレビュー用
struct AdMobBannerView_Previews: PreviewProvider {
    static var previews: some View {
        AdMobBannerView()
            .frame(height: 50)
            .previewLayout(.sizeThatFits)
    }
}
