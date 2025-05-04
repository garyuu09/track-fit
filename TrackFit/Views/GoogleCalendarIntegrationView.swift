//
//  GoogleCalendarIntegrationView.swift
//  TrackFit
//
//  Created by Ryuga on 2025/05/04.
//

import SwiftUI

struct GoogleCalendarIntegrationView: View {
    let onFinish: (Bool) -> Void
    @State private var animateSteps = false

    var body: some View {
        ZStack {
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Image(systemName: "calendar.badge.clock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundColor(.accentColor)
                        .padding(.top, 40)

                    Text("Googleカレンダーと連携")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    Text("次のような機能が使えるようになります。")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 24) {
                        Group {
                            HStack(alignment: .top) {
                                Image(systemName: "1.circle.fill")
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading) {
                                    Text("カレンダーと接続")
                                        .font(.headline)
                                    Text("トレーニング記録をGoogleカレンダーと同期します。")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .opacity(animateSteps ? 1 : 0)
                            .scaleEffect(animateSteps ? 1 : 0.9)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: animateSteps)
                        }

                        Group {
                            HStack(alignment: .top) {
                                Image(systemName: "2.circle.fill")
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading) {
                                    Text("日々の記録を可視化")
                                        .font(.headline)
                                    Text("カレンダー上で過去のトレーニングを振り返れます。")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .opacity(animateSteps ? 1 : 0)
                            .scaleEffect(animateSteps ? 1 : 0.9)
                            .animation(.easeOut(duration: 0.5).delay(0.4), value: animateSteps)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    HStack(spacing: 20) {
                        Button {
                            onFinish(false)
                        } label: {
                            Label("後で", systemImage: "xmark")
                                .frame(minWidth: 100)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task {
                                let success = try await GoogleCalendarAPI.linkGoogleCalendar()
                                if success {
                                    onFinish(true)
                                }
                            }
                        } label: {
                            Label("連携する", systemImage: "link")
                                .frame(minWidth: 100)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: UUID())
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) {
                        animateSteps = true
                    }
                }
            }
        }
    }
}

#Preview {
    GoogleCalendarIntegrationView(onFinish: { _ in })
}
