//
//  PrivacyPolicyView.swift
//  TrackFit
//
//  Created by Claude on 2025/06/23.
//

import SwiftUI
import UIKit
import WebKit

struct PrivacyPolicyView: View {
    @StateObject private var webViewModel = PrivacyPolicyWebViewModel()

    var body: some View {
        ZStack {
            if webViewModel.showError {
                VStack(spacing: 24) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)

                    VStack(spacing: 8) {
                        Text("接続できません")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("インターネットに接続されていません")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button("再試行") {
                        webViewModel.retry()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 32)
            } else {
                PrivacyPolicyWebView(viewModel: webViewModel)
            }
        }
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }
}

class PrivacyPolicyWebViewModel: NSObject, ObservableObject {
    @Published var showError = false
    private weak var webView: WKWebView?
    private let url = URL(string: "https://garyuu09.github.io/track-fit-privacy-policy/")!

    func setWebView(_ webView: WKWebView) {
        self.webView = webView
        webView.navigationDelegate = self
        loadURL()
    }

    private func loadURL() {
        let request = URLRequest(url: url)
        webView?.load(request)
    }

    func retry() {
        showError = false
        loadURL()
    }
}

extension PrivacyPolicyWebViewModel: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        DispatchQueue.main.async {
            self.showError = true
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.showError = true
        }
    }
}

struct PrivacyPolicyWebView: UIViewRepresentable {
    let viewModel: PrivacyPolicyWebViewModel

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        viewModel.setWebView(webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // ViewModelが管理
    }
}

#Preview {
    PrivacyPolicyView()
}
