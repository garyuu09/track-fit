//
//  AlertBannerView.swift
//  TrackFit
//
//  Created by Ryuga on 2025/05/06.
//

import SwiftUI

struct AlertBannerView: View {
    @Binding var isShowCalendarIntegration: Bool
    @Binding var showIntegrationBanner: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text("Google カレンダーが連携されていません")
                .font(.footnote)
            Spacer()
            Button {
                isShowCalendarIntegration = true
            } label: {
                Text("今すぐ連携")
            }
            .font(.subheadline)
            .buttonStyle(.borderedProminent)
            Button(action: { showIntegrationBanner = false }) {
                Image(systemName: "xmark")
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
