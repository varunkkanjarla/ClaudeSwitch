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
            timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
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
        guard let pids = runningPIDs[account.id], !pids.isEmpty else {
            return "Not running · sign-in state unknown"
        }
        return "Running · PID " + pids.map(String.init).joined(separator: ", ") + " · identity not verified"
    }
}

enum DesktopProfileDetector {
    static func runningProcessIDs(_ profiles: [UUID: URL]) throws -> [UUID: [Int32]] {
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

        var matches: [UUID: [Int32]] = [:]
        for line in listing.split(whereSeparator: \\.isNewline) {
            let parts = line.split(maxSplits: 1, whereSeparator: \\.isWhitespace)
            guard parts.count == 2, let pid = Int32(parts[0]) else { continue }
            let command = String(parts[1])
            let lower = command.lowercased()
            guard !lower.contains("--type="),
                  lower.contains(".app/contents/macos/"),
                  lower.contains("claude") else { continue }

            for (accountID, profileURL) in profiles {
                let argument = "--user-data-dir=" + profileURL.standardizedFileURL.path
                if command.contains(argument) {
                    matches[accountID, default: []].append(pid)
                }
            }
        }
        return matches.mapValues { Array(Set($0)).sorted() }
    }
}
