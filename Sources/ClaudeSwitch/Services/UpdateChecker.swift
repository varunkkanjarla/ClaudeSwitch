import Foundation

struct GitHubRelease: Decodable {
    let tag_name: String
    let html_url: URL
    let name: String?
}

enum UpdateChecker {
    static func latestRelease(repository: String) async throws -> GitHubRelease {
        let slug = repository.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = slug.split(separator: "/")
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.")
        guard parts.count == 2, parts.allSatisfy({ !$0.isEmpty && $0.unicodeScalars.allSatisfy(allowed.contains) }) else {
            throw NSError(domain: "ClaudeSwitch.Update", code: 1, userInfo: [NSLocalizedDescriptionKey: "Enter a GitHub repository as owner/repository."])
        }
        let url = URL(string: "https://api.github.com/repos/\(parts[0])/\(parts[1])/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("ClaudeSwitch/1.0.0-beta.2", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "ClaudeSwitch.Update", code: 2, userInfo: [NSLocalizedDescriptionKey: "GitHub did not return a published release. Check the repository and try again."])
        }
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }
}
