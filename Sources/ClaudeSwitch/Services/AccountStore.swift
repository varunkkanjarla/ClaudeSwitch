import Foundation
import SwiftUI

@MainActor
final class AccountStore: ObservableObject {
    @Published private(set) var accounts: [ClaudeAccount] = []
    @Published var statusMessage = "Ready"
    @Published var preferredBrowser = "Default browser"
    @Published var showBrowserOption = false
    @Published var updatesEnabled = false
    @Published var githubRepository = ""
    @Published var onboardingCompleted = false

    let baseDirectory: URL
    private let accountsFile: URL
    private let settingsFile: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        baseDirectory = support.appendingPathComponent("ClaudeSwitch", isDirectory: true)
        accountsFile = baseDirectory.appendingPathComponent("accounts.json")
        settingsFile = baseDirectory.appendingPathComponent("settings.json")
        do { try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true) }
        catch { statusMessage = "Could not create ClaudeSwitch data folder: \(error.localizedDescription)" }
        load()
    }

    func addAccount(_ account: ClaudeAccount) {
        let cleanName = account.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { statusMessage = "Give this account a label first."; return }
        guard !accounts.contains(where: { $0.id == account.id }) else { statusMessage = "That account already exists."; return }
        var value = account
        value.name = cleanName
        value.tag = account.tag.trimmingCharacters(in: .whitespacesAndNewlines)
        value.email = account.email.trimmingCharacters(in: .whitespacesAndNewlines)
        accounts.append(value)
        save(); statusMessage = "Added \(cleanName)."
    }

    func updateAccount(_ account: ClaudeAccount) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[index] = account; save(); statusMessage = "Updated \(account.name)."
    }

    func deleteAccount(_ account: ClaudeAccount) {
        accounts.removeAll { $0.id == account.id }
        save(); statusMessage = "Removed \(account.name). Only its ClaudeSwitch metadata was removed; external sessions and Code data were not touched."
    }

    func codeDirectory(for account: ClaudeAccount) -> URL {
        baseDirectory.appendingPathComponent("ClaudeCode", isDirectory: true).appendingPathComponent(account.id.uuidString, isDirectory: true)
    }

    func prepareCodeDirectory(for account: ClaudeAccount) throws -> URL {
        let url = codeDirectory(for: account)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func updateStatus(_ message: String) { statusMessage = message }
    func account(id: UUID) -> ClaudeAccount? { accounts.first { $0.id == id } }

    func saveSettings() { save() }

    func exportDiagnostics() throws -> URL {
        let report: [String: Any] = [
            "app": "ClaudeSwitch", "version": "1.0.0-beta.2", "macOS": ProcessInfo.processInfo.operatingSystemVersionString,
            "accountCount": accounts.count, "browserOptionEnabled": showBrowserOption,
            "updatesEnabled": updatesEnabled, "createdAt": ISO8601DateFormatter().string(from: .now),
            "note": "This diagnostic export intentionally excludes account emails, account labels, browser data, Claude credentials and Claude Code configuration contents."
        ]
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent("ClaudeSwitch-Diagnostics.json")
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: destination, options: .atomic)
        return destination
    }

    private func load() {
        if FileManager.default.fileExists(atPath: accountsFile.path) {
            do {
                let data = try Data(contentsOf: accountsFile)
                accounts = try JSONDecoder().decode([ClaudeAccount].self, from: data)
            } catch {
                // Preserve malformed user data rather than silently replacing it with defaults.
                accounts = []
                statusMessage = "Could not read accounts.json. Your file was preserved; export it before attempting recovery. (\(error.localizedDescription))"
            }
        } else {
            // Start empty so users define their own account labels rather than inheriting fixed identities.
            accounts = []
            save()
        }
        if let data = try? Data(contentsOf: settingsFile), let settings = try? JSONDecoder().decode(Settings.self, from: data) {
            preferredBrowser = settings.preferredBrowser
            showBrowserOption = settings.showBrowserOption
            updatesEnabled = settings.updatesEnabled
            githubRepository = settings.githubRepository
            onboardingCompleted = settings.onboardingCompleted
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
            try JSONEncoder().encode(accounts).write(to: accountsFile, options: .atomic)
            let settings = Settings(preferredBrowser: preferredBrowser, showBrowserOption: showBrowserOption, updatesEnabled: updatesEnabled, githubRepository: githubRepository, onboardingCompleted: onboardingCompleted)
            try JSONEncoder().encode(settings).write(to: settingsFile, options: .atomic)
        } catch { statusMessage = "Could not save settings: \(error.localizedDescription)" }
    }
}

private struct Settings: Codable {
    var preferredBrowser: String
    var showBrowserOption: Bool
    var updatesEnabled: Bool
    var githubRepository: String
    var onboardingCompleted: Bool

    private enum CodingKeys: String, CodingKey { case preferredBrowser, showBrowserOption, updatesEnabled, githubRepository, onboardingCompleted }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(preferredBrowser, forKey: .preferredBrowser)
        try container.encode(showBrowserOption, forKey: .showBrowserOption)
        try container.encode(updatesEnabled, forKey: .updatesEnabled)
        try container.encode(githubRepository, forKey: .githubRepository)
        try container.encode(onboardingCompleted, forKey: .onboardingCompleted)
    }

    init(preferredBrowser: String = "Default browser", showBrowserOption: Bool = false, updatesEnabled: Bool = false, githubRepository: String = "", onboardingCompleted: Bool = false) {
        self.preferredBrowser = preferredBrowser
        self.showBrowserOption = showBrowserOption
        self.updatesEnabled = updatesEnabled
        self.githubRepository = githubRepository
        self.onboardingCompleted = onboardingCompleted
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        preferredBrowser = try values.decodeIfPresent(String.self, forKey: .preferredBrowser) ?? "Default browser"
        showBrowserOption = try values.decodeIfPresent(Bool.self, forKey: .showBrowserOption) ?? false
        updatesEnabled = try values.decodeIfPresent(Bool.self, forKey: .updatesEnabled) ?? false
        githubRepository = try values.decodeIfPresent(String.self, forKey: .githubRepository) ?? ""
        onboardingCompleted = try values.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
    }
}
