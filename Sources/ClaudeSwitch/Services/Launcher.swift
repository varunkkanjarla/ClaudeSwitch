import AppKit
import Foundation

@MainActor
enum Launcher {
    static func openWeb(account: ClaudeAccount, store: AccountStore) {
        guard let url = URL(string: "https://claude.ai") else { return }
        if store.preferredBrowser == "Default browser" {
            let opened = NSWorkspace.shared.open(url)
            store.updateStatus(opened ? "Opened Claude in your default browser. This uses its current signed-in account." : "Could not open your default browser.")
        } else if let appURL = browserURL(named: store.preferredBrowser) {
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                Task { @MainActor in
                    store.updateStatus(error.map { "Could not open browser: \($0.localizedDescription)" } ?? "Opened Claude in \(store.preferredBrowser). It uses that browser profile's current login.")
                }
            }
        } else {
            store.updateStatus("\(store.preferredBrowser) was not found. Choose another browser in Settings.")
        }
    }

    static func openCode(account: ClaudeAccount, store: AccountStore) {
        do {
            let workingDirectory = (account.workingDirectory as NSString).expandingTildeInPath
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: workingDirectory, isDirectory: &isDirectory), isDirectory.boolValue else {
                store.updateStatus("The CLI working folder for \(account.name) no longer exists. Edit the account and choose a valid folder.")
                return
            }
            let configExport = account.useExistingSetup ? "" : "export CLAUDE_CONFIG_DIR=\(shellQuote(try store.prepareCodeDirectory(for: account).path)) && "
            let command = "cd \(shellQuote(workingDirectory)) && \(configExport)if command -v claude >/dev/null 2>&1; then claude; else echo 'Claude Code CLI was not found. Install it and ensure claude is on PATH.'; fi"
            let escaped = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            let script = "tell application \"Terminal\" to do script \"\(escaped)\""
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            try process.run()
            store.updateStatus("Opened Claude Code CLI for \(account.name). First launch may ask you to authenticate.")
        } catch {
            store.updateStatus("Could not launch Claude Code CLI: \(error.localizedDescription). Check Terminal automation permission.")
        }
    }

    static func openDesktop(account: ClaudeAccount, store: AccountStore, runtime: DesktopProfileRuntime? = nil) {
        guard let appURL = desktopAppURL() else {
            store.updateStatus("Claude Desktop was not found. Install the official macOS app first.")
            return
        }

        if account.useExistingSetup {
            openDefaultDesktop(store: store, launchedMessage: "Opened Claude Desktop with your existing profile for \(account.name).")
            return
        }

        do {
            let profileURL = try store.prepareDesktopProfileDirectory(for: account)
            if let pid = try DesktopProfileDetector.runningProcessIDs([account.id: profileURL])[account.id]?.first,
               let runningApp = NSRunningApplication(processIdentifier: pid) {
                runningApp.activate(options: [.activateAllWindows])
                store.updateStatus("Activated the already-running Desktop profile for " + account.name + ".")
                runtime?.refresh()
                return
            }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.arguments = [
                "--user-data-dir=" + profileURL.path,
                "--no-first-run"
            ]
            configuration.createsNewApplicationInstance = true
            // Points this profile's Code tab at the same config folder as the account's CLI instead of ~/.claude.
            configuration.environment = ["CLAUDE_CONFIG_DIR": try store.prepareCodeDirectory(for: account).path]
            NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
                Task { @MainActor in
                    if let error {
                        store.updateStatus("Could not launch isolated Desktop profile for " + account.name + ": " + error.localizedDescription)
                    } else {
                        store.updateStatus("Launched Desktop profile for " + account.name + ". Sign in separately if needed. Signed-in identity is not verified by ClaudeSwitch.")
                        runtime?.refresh()
                    }
                }
            }
        } catch {
            store.updateStatus("Could not prepare Desktop profile for " + account.name + ": " + error.localizedDescription)
        }
    }

    /// Opens the default-profile Desktop. A new instance is required: with only isolated profiles running,
    /// a plain open would just activate one of those instead.
    static func openDefaultDesktop(store: AccountStore, launchedMessage: String = "Reopened your main Claude Desktop.") {
        guard let appURL = desktopAppURL() else {
            store.updateStatus("Claude Desktop was not found. Install the official macOS app first.")
            return
        }
        let profiles = store.accounts.map { (account: $0, profile: store.desktopProfileDirectory(for: $0)) }
        if let running = (try? DesktopProfileDetector.runningDesktops(profiles: profiles))?.first(where: \.isDefaultProfile) {
            running.app.activate(options: [.activateAllWindows])
            store.updateStatus("Activated your main Claude Desktop.")
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
            Task { @MainActor in
                store.updateStatus(error.map { "Claude Desktop launch failed: \($0.localizedDescription)" } ?? launchedMessage)
            }
        }
    }

    /// Every other Claude Desktop that could receive the claude:// sign-in link meant for this account's profile.
    static func competingDesktops(for account: ClaudeAccount, store: AccountStore) throws -> [RunningDesktop] {
        let profiles = store.accounts.map { (account: $0, profile: store.desktopProfileDirectory(for: $0)) }
        return try DesktopProfileDetector.runningDesktops(profiles: profiles).filter { $0.accountID != account.id }
    }

    /// Quits the given Desktops normally (never force-quits), then opens this account's profile so it is the only
    /// Claude running when the browser hands back the sign-in link. Returns false if any instance would not quit.
    static func beginDesktopSignIn(account: ClaudeAccount, store: AccountStore, runtime: DesktopProfileRuntime?, closing: [RunningDesktop]) async -> Bool {
        closing.forEach { _ = $0.app.terminate() }
        let deadline = Date().addingTimeInterval(15)
        while closing.contains(where: { !$0.app.isTerminated }), Date() < deadline {
            try? await Task.sleep(for: .milliseconds(250))
        }
        let stillRunning = closing.filter { !$0.app.isTerminated }.map(\.label)
        guard stillRunning.isEmpty else {
            store.updateStatus("Sign-in stopped: " + stillRunning.joined(separator: ", ") + " did not quit. Close it yourself (check for an open prompt), then try again.")
            return false
        }
        openDesktop(account: account, store: store, runtime: runtime)
        return true
    }

    private static func desktopAppURL() -> URL? {
        let bundleMatch = DesktopProfileDetector.desktopBundleIDs.compactMap { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) }.first
        let localCandidates = [
            "/Applications/Claude.app",
            (NSHomeDirectory() as NSString).appendingPathComponent("Applications/Claude.app"),
            "/Applications/Claude Desktop.app"
        ].map { URL(fileURLWithPath: $0, isDirectory: true) }
        return bundleMatch ?? localCandidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private static func browserURL(named name: String) -> URL? {
        let bundleIDs: [String: String] = [
            "Google Chrome": "com.google.Chrome", "Safari": "com.apple.Safari",
            "Microsoft Edge": "com.microsoft.edgemac", "Brave": "com.brave.Browser", "Firefox": "org.mozilla.firefox"
        ]
        guard let id = bundleIDs[name] else { return nil }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: id)
    }

    private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
