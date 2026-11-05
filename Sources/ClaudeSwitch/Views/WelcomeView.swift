import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var store: AccountStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @State private var showBrowser = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.left.arrow.right.circle.fill").font(.system(size: 38)).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Welcome to ClaudeSwitch").font(.title.bold())
                    Text("Your Claude environments, one menu bar away.").foregroundStyle(.secondary)
                }
            }
            Divider()
            Text("Choose how you work").font(.headline)
            HStack(alignment: .top, spacing: 14) {
                integrationCard(icon: "macwindow", title: "Claude Desktop", detail: "Open the installed Claude macOS app. It uses the app's existing login.")
                integrationCard(icon: "terminal", title: "Claude Code CLI", detail: "Open the CLI in Terminal with a separate configuration folder for each ClaudeSwitch account.")
            }
            GroupBox {
                Toggle("Also show an optional Browser action", isOn: $showBrowser)
                Text("Browser opens your chosen browser profile. It is not an independent login session.").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack {
                Button("Skip for now") { finish() }.buttonStyle(.plain)
                Spacer()
                Button("Add my first account") { store.showBrowserOption = showBrowser; store.saveSettings(); finish(openAccounts: true) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
    }

    private func integrationCard(icon: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon).font(.title).foregroundStyle(.tint)
            Text(title).font(.headline)
            Text(detail).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 145, alignment: .topLeading)
        .padding(14).background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
    }

    private func finish(openAccounts: Bool = false) {
        store.onboardingCompleted = true
        store.showBrowserOption = showBrowser
        store.saveSettings()
        dismiss()
        if openAccounts {
            openWindow(id: "dashboard")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                NotificationCenter.default.post(name: .claudeSwitchRequestAddAccount, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let claudeSwitchRequestAddAccount = Notification.Name("ClaudeSwitch.RequestAddAccount")
}
