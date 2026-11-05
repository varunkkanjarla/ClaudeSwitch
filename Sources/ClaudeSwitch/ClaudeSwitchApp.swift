import SwiftUI

@main
struct ClaudeSwitchApp: App {
    @StateObject private var store = AccountStore()

    var body: some Scene {
        MenuBarExtra("ClaudeSwitch", systemImage: "arrow.left.arrow.right.circle") {
            MenuBarView().environmentObject(store)
        }
        .menuBarExtraStyle(.window)

        WindowGroup("ClaudeSwitch", id: "dashboard") {
            DashboardView().environmentObject(store).frame(minWidth: 720, minHeight: 540)
        }
        .defaultSize(width: 820, height: 620)

        WindowGroup("Welcome to ClaudeSwitch", id: "onboarding") {
            WelcomeView().environmentObject(store).frame(width: 560, height: 520)
        }
        .windowResizability(.contentSize)
    }
}
