import Foundation

struct ClaudeAccount: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var tag: String
    var email: String
    var icon: String
    var color: String
    var createdAt: Date
    var workingDirectory: String

    init(id: UUID = UUID(), name: String, tag: String = "", email: String = "", icon: String = "person.crop.circle.fill", color: String = "#8B8B8B", createdAt: Date = .now, workingDirectory: String = NSHomeDirectory()) {
        self.id = id
        self.name = name
        self.tag = tag
        self.email = email
        self.icon = icon
        self.color = color
        self.createdAt = createdAt
        self.workingDirectory = workingDirectory
    }

    private enum CodingKeys: String, CodingKey { case id, name, tag, email, icon, color, createdAt, workingDirectory, kind }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let legacyKind = try c.decodeIfPresent(String.self, forKey: .kind) ?? "Personal"
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? legacyKind
        tag = try c.decodeIfPresent(String.self, forKey: .tag) ?? ""
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? (legacyKind == "Work" ? "briefcase.fill" : "person.crop.circle.fill")
        color = try c.decodeIfPresent(String.self, forKey: .color) ?? (legacyKind == "Work" ? "#4F8CFF" : "#A78BFA")
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        workingDirectory = try c.decodeIfPresent(String.self, forKey: .workingDirectory) ?? NSHomeDirectory()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(tag, forKey: .tag)
        try c.encode(email, forKey: .email)
        try c.encode(icon, forKey: .icon)
        try c.encode(color, forKey: .color)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(workingDirectory, forKey: .workingDirectory)
    }
}
