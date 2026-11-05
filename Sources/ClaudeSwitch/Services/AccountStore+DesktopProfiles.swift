import Foundation

extension AccountStore {
    func desktopProfileDirectory(for account: ClaudeAccount) -> URL {
        baseDirectory
            .appendingPathComponent("DesktopProfiles", isDirectory: true)
            .appendingPathComponent(account.id.uuidString, isDirectory: true)
    }

    func prepareDesktopProfileDirectory(for account: ClaudeAccount) throws -> URL {
        let directory = desktopProfileDirectory(for: account)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: directory.path
        )
        return directory
    }
}
