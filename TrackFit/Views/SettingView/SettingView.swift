//
//  SettingView.swift
//  TrackFit
//
//  Created by Ryuga on 2025/03/08.
//

import SwiftUI

enum DisplayMode: String {
    case light, dark, system
}

enum CalendarEventColor: String, CaseIterable, Identifiable {
    case みかん = "4"
    case トマト = "11"
    case フラミンゴ = "5"
    case バナナ = "9"
    case セージ = "2"
    case ピーコック = "6"
    case ブルーベリー = "1"
    case ラベンダー = "3"
    case グレープ = "10"
    case グラファイト = "8"
    case デフォルト = "7"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .みかん: return "みかん"
        case .トマト: return "トマト"
        case .フラミンゴ: return "フラミンゴ"
        case .バナナ: return "バナナ"
        case .セージ: return "セージ"
        case .ピーコック: return "ピーコック"
        case .ブルーベリー: return "ブルーベリー"
        case .ラベンダー: return "ラベンダー"
        case .グレープ: return "グレープ"
        case .グラファイト: return "グラファイト"
        case .デフォルト: return "デフォルト"
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .みかん: return .orange
        case .トマト: return .red
        case .フラミンゴ: return .pink
        case .バナナ: return .yellow
        case .セージ: return .green
        case .ピーコック: return .teal
        case .ブルーベリー: return .blue
        case .ラベンダー: return .purple
        case .グレープ: return .purple
        case .グラファイト: return .gray
        case .デフォルト: return .primary
        }
    }
}

struct SettingView: View {
    @AppStorage("displayMode") private var displayMode: DisplayMode = .system
    @AppStorage("isCalendarFeatureEnabled") private var isCalendarFeatureEnabled: Bool = true
    @AppStorage("calendarEventColor") private var calendarEventColor: CalendarEventColor = .みかん
    @State private var isGoogleCalendarLinked: Bool = false
    @State private var linkedAccountEmail: String? = nil
    @State private var accessToken: String? = nil
    @State private var isShowCalendarIntegration: Bool = false
    @State private var showIntegrationBanner: Bool = false
    @State private var isShowingExerciseManagement = false
    @Environment(\.modelContext) private var modelContext
    let version =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        ?? "Unknown"
    #if DEBUG
        let build =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    #endif

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("外部連携")) {
                    // カレンダー機能のオンオフトグル
                    HStack {
                        Text("カレンダー連携機能")
                        Spacer()
                        Toggle("", isOn: $isCalendarFeatureEnabled)
                            .onChange(of: isCalendarFeatureEnabled) { _, newValue in
                                if !newValue {
                                    // 機能をオフにした場合、連携も解除
                                    if isGoogleCalendarLinked {
                                        GoogleCalendarAPI.unlinkGoogleCalendar()
                                        UserDefaults.standard.set(false, forKey: "isCalendarLinked")
                                        isGoogleCalendarLinked = false
                                        linkedAccountEmail = nil
                                        accessToken = nil
                                    }
                                }
                            }
                    }

                    // カレンダー機能が有効な場合のみGoogleカレンダー連携を表示
                    if isCalendarFeatureEnabled {
                        HStack {
                            Text("Googleカレンダー")
                            Spacer()
                            if isGoogleCalendarLinked, let email = linkedAccountEmail {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "calendar.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Googleカレンダーと連携中")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)

                                        Text(email)
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Button("連携を解除") {
                                            GoogleCalendarAPI.unlinkGoogleCalendar()
                                            UserDefaults.standard.set(
                                                false, forKey: "isCalendarLinked")
                                            isGoogleCalendarLinked = false
                                            UserDefaults.standard.set(
                                                true, forKey: "showIntegrationBanner")
                                            linkedAccountEmail = nil
                                            accessToken = nil
                                        }
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    }
                                }
                            } else {
                                Button("連携する") {
                                    isShowCalendarIntegration = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        // カレンダー機能が有効で連携中の場合のみイベント色設定を表示
                        if isGoogleCalendarLinked {
                            HStack {
                                Text("イベントの色")
                                Spacer()
                                Picker("", selection: $calendarEventColor) {
                                    ForEach(CalendarEventColor.allCases) { color in
                                        HStack {
                                            Circle()
                                                .fill(color.swiftUIColor)
                                                .frame(width: 16, height: 16)
                                            Text(color.displayName)
                                        }
                                        .tag(color)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                }

                Section("App Settings") {
                    Picker("テーマカラー", selection: $displayMode) {
                        Text("ライト").tag(DisplayMode.light)
                        Text("ダーク").tag(DisplayMode.dark)
                        Text("システム").tag(DisplayMode.system)
                    }
                    .pickerStyle(.automatic)

                    Button(action: {
                        isShowingExerciseManagement = true
                    }) {
                        HStack {
                            Text("種目管理")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Section("About TrackFit") {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("プライバシーポリシー")
                    }
                    Text("TrackFitをレビューする")

                }
                Section {
                } footer: {
                    VStack(
                        alignment: .center,
                        content: {
                            VStack {
                                Text("©TrackFit")
                                    .font(.caption)
                                HStack(spacing: 0) {
                                    Text("Ver. \(version)")
                                        .font(.caption2)
                                    #if DEBUG
                                        Text("(\(build))")
                                            .font(.caption2)
                                    #endif
                                }
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("設定")
            .onAppear {
                if isCalendarFeatureEnabled {
                    loadLinkedStatus()
                    // 連携状態の最新チェック
                    Task {
                        await GoogleCalendarAPI.checkAndUpdateLinkingStatus()
                        // チェック後に最新状態を再読み込み
                        await MainActor.run {
                            loadLinkedStatus()
                        }
                    }
                }
            }
            // モーダルで連携画面を表示（カレンダー機能が有効な場合のみ）
            .sheet(
                isPresented: Binding(
                    get: { isShowCalendarIntegration && isCalendarFeatureEnabled },
                    set: { isShowCalendarIntegration = $0 }
                )
            ) {
                GoogleCalendarIntegrationView(
                    onFinish: { didLink in
                        if didLink {
                            UserDefaults.standard.set(true, forKey: "isCalendarLinked")
                            accessToken = KeychainHelper.shared.loadString(
                                forKey: KeychainHelper.GoogleTokenKeys.accessToken)
                            linkedAccountEmail = KeychainHelper.shared.loadString(
                                forKey: KeychainHelper.GoogleTokenKeys.email)
                            isGoogleCalendarLinked = true
                        }
                        isShowCalendarIntegration = false
                        // 連携状態を再読み込みして最新状態を反映
                        if isCalendarFeatureEnabled {
                            loadLinkedStatus()
                        }
                    },
                    showIntegrationBanner: $showIntegrationBanner
                )
            }
            .sheet(isPresented: $isShowingExerciseManagement) {
                ExerciseManagementView(modelContext: modelContext)
            }
        }
    }

    // 連携状態を読み込み（Keychainから安全に取得）
    func loadLinkedStatus() {
        let isLinked = UserDefaults.standard.bool(forKey: "isCalendarLinked")
        let keychain = KeychainHelper.shared
        let savedToken = keychain.loadString(forKey: KeychainHelper.GoogleTokenKeys.accessToken)
        let savedEmail = keychain.loadString(forKey: KeychainHelper.GoogleTokenKeys.email)

        if isLinked && savedToken != nil && savedEmail != nil {
            self.accessToken = savedToken
            self.isGoogleCalendarLinked = true
            self.linkedAccountEmail = savedEmail
        } else {
            self.isGoogleCalendarLinked = false
            self.linkedAccountEmail = nil
            self.accessToken = nil
            // 不整合がある場合はフラグをfalseに統一
            if isLinked {
                UserDefaults.standard.set(false, forKey: "isCalendarLinked")
            }
        }
    }
}

#Preview {
    SettingView()
}
