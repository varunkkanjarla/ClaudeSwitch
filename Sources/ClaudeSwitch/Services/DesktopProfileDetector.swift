import Foundation

enum DesktopProfileDetector {
    static func runningProcessIDs(_ profiles: [UUID: URL]) throws -> [UUID: [Int32]] {
        let process = Process(), pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid=,command="]
        process.standardOutput = pipe
        process.standardError = Pipe()
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0, let text = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "ClaudeSwitch", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not inspect process list"])
        }
        var result: [UUID: [Int32]] = [:]
        for line in text.split(whereSeparator: \\.isNewline) {
            let p = line.split(maxSplits: 1, whereSeparator: \\.isWhitespace)
            guard p.count == 2, let pid = Int32(p[0]) else { continue }
            let cmd = String(p[1]), lower = cmd.lowercased()
            guard !lower.contains("--type="), lower.contains(".app/contents/macos/"), lower.contains("claude") else { continue }
            for (id, url) in profiles where cmd.contains("--user-data-dir=\\(url.path)") {
                result[id, default: []].append(pid)
            }
        }
        return result.mapValues { Array(Set($0)).sorted() }
    }
}
