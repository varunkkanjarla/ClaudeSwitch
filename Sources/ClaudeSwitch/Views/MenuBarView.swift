import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject private var store: AccountStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("ClaudeSwitch", systemImage: "arrow.left.arrow.right.circle.fill").font(.headline)
                Spacer()
                Button { openDashboard() } label: { Image(systemName: "slider.horizontal.3") }
                    .buttonStyle(.borderless).help("Settings and account management")
            }
            Divider()
            Text("Desktop opens the app's current login. CLI keeps a separate configuration per account.")
                .font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if store.accounts.isEmpty {
                ContentUnavailableView("No accounts yet", systemImage: "person.crop.circle.badge.plus", description: Text("Add your first account in ClaudeSwitch settings."))
            } else {
                ForEach(store.accounts) { account in
                    VStack(alignment: .leading, spacing: 9) {
                        HStack(spacing: 10) {
                            Image(systemName: account.icon).foregroundStyle(Color(hex: account.color)).font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.name).font(.subheadline.weight(.semibold))
                                Text(account.email.isEmpty ? (account.tag.isEmpty ? "Claude account" : account.tag) : account.email)
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                        }
                        HStack(spacing: 8) {
                            Button { Launcher.openDesktop(account: account, store: store) } label: { Label("Desktop", systemImage: "macwindow") }
                            Button { Launcher.openCode(account: account, store: store) } label: { Label("CLI", systemImage: "terminal") }
                            if store.showBrowserOption {
                                Button { Launcher.openWeb(account: account, store: store) } label: { Label("Browser", systemImage: "globe") }
                            }
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                    }
                    .padding(10).background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 11))
                }
            }
            Divider()
            Text(store.statusMessage).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            HStack {
                Button("Manage accounts") { openDashboard() }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }.keyboardShortcut("q")
            }
        }
        .padding(14).frame(width: 340)
        .onAppear {
            if !store.onboardingCompleted { openWindow(id: "onboarding") }
        }
    }

    private func openDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "dashboard")
    }
}

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let number = UInt64(value, radix: 16) ?? 0x888888
        self.init(.sRGB, red: Double((number >> 16) & 0xff) / 255, green: Double((number >> 8) & 0xff) / 255, blue: Double(number & 0xff) / 255, opacity: 1)
    }
}
