import AppKit
import Foundation
import SwiftUI

@MainActor
final class DesktopProfileRuntime: ObservableObject {
    @Published private(set) var runningPIDs: [UUID: [Int32]] = [:]
    @Published private(set) var detectionMessage = "Checking Claude Desktop processes…"
    private var profiles: [UUID: URL] = [:]
    private var timer: Timer?

    func configure(accounts: [ClaudeAccount], baseDirectory: URL) {
        profiles = Dictionary(uniqueKeysWithValues: accounts.map { account in
            (account.id, baseDirectory.appendingPathComponent("DesktopProfiles", isDirectory: true)
                .appendingPathComponent(account.id.uuidString, isDirectory: true))
        })
        refresh()
        if timer == nil {
            let runtime = self
            timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
                Task { @MainActor in runtime.refresh() }
            }
        }
    }

    func refresh() {
        do {
            runningPIDs = try DesktopProfileDetector.runningProcessIDs(profiles)
            detectionMessage = "Process detection active. Signed-in identity is not inspected."
        } catch {
            detectionMessage = "Process detection unavailable: " + error.localizedDescription
        }
    }

    func status(for account: ClaudeAccount) -> String {
        if account.useExistingSetup { return "Uses your existing Desktop profile" }
        guard let pids = runningPIDs[account.id], !pids.isEmpty else {
            return "Not running · sign-in state unknown"
        }
        return "Running · PID " + pids.map(String.init).joined(separator: ", ") + " · identity not verified"
    }
}

/// A running Claude Desktop main process and which profile it uses.
struct RunningDesktop {
    let app: NSRunningApplication
    let label: String
    let accountID: UUID?
    let isDefaultProfile: Bool
}

enum DesktopProfileDetector {
    static let desktopBundleIDs = ["com.anthropic.claudefordesktop", "com.anthropic.Claude"]

    static func runningProcessIDs(_ profiles: [UUID: URL]) throws -> [UUID: [Int32]] {
        var matches: [UUID: [Int32]] = [:]
        for (pid, command) in try desktopCommands() {
            for (accountID, profileURL) in profiles where command.contains(profileArgument(profileURL)) {
                matches[accountID, default: []].append(pid)
            }
        }
        return matches.mapValues { Array(Set($0)).sorted() }
    }

    /// Claude Desktop instances found by bundle ID, so ClaudeSwitch's own process is never matched.
    static func runningDesktops(profiles: [(account: ClaudeAccount, profile: URL)]) throws -> [RunningDesktop] {
        let commands = try desktopCommands()
        return desktopBundleIDs.flatMap { NSRunningApplication.runningApplications(withBundleIdentifier: $0) }.map { app in
            let command = commands[app.processIdentifier] ?? ""
            if let match = profiles.first(where: { command.contains(profileArgument($0.profile)) }) {
                return RunningDesktop(app: app, label: match.account.name, accountID: match.account.id, isDefaultProfile: false)
            }
            let isDefault = !command.contains("--user-data-dir=")
            return RunningDesktop(app: app, label: isDefault ? "Main Claude Desktop" : "Another Claude Desktop profile", accountID: nil, isDefaultProfile: isDefault)
        }
    }

    private static func profileArgument(_ profileURL: URL) -> String {
        "--user-data-dir=" + profileURL.standardizedFileURL.path
    }

    /// Command lines of Claude main processes (renderer and GPU helpers excluded), keyed by PID.
    private static func desktopCommands() throws -> [Int32: String] {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid=,command="]
        process.standardOutput = pipe
        process.standardError = Pipe()
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0, let listing = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "ClaudeSwitch", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not inspect the macOS process list."])
        }

        var commands: [Int32: String] = [:]
        for line in listing.split(whereSeparator: \.isNewline) {
            let parts = line.split(maxSplits: 1, whereSeparator: \.isWhitespace)
            guard parts.count == 2, let pid = Int32(parts[0]) else { continue }
            let command = String(parts[1])
            let lower = command.lowercased()
            guard !lower.contains("--type="),
                  lower.contains("claude") else { continue }
            commands[pid] = command
        }
        return commands
    }
}
