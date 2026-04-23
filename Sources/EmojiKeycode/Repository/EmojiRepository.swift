import Foundation

struct EmojiMatch: Equatable, Sendable {
    let shortcode: String
    let emoji: String
}

final class EmojiRepository: @unchecked Sendable {
    private let entries: [EmojiEntry]
    private let byShortcode: [String: String]
    private let sortedShortcodes: [String]

    init(entries: [EmojiEntry]) {
        self.entries = entries
        var map: [String: String] = [:]
        map.reserveCapacity(entries.count * 2)
        for entry in entries {
            for name in entry.names {
                map[name.lowercased()] = entry.emoji
            }
        }
        self.byShortcode = map
        self.sortedShortcodes = map.keys.sorted()
    }

    static func loadBundled() throws -> EmojiRepository {
        let url = try bundledURL()
        let data = try Data(contentsOf: url)
        let entries = try JSONDecoder().decode([EmojiEntry].self, from: data)
        return EmojiRepository(entries: entries)
    }

    private static func bundledURL() throws -> URL {
        if let url = Bundle.main.url(forResource: "emojis", withExtension: "json") {
            return url
        }
        let exe = Bundle.main.executableURL ?? URL(fileURLWithPath: CommandLine.arguments[0])
        let candidates = [
            exe.deletingLastPathComponent().appendingPathComponent("../Resources/emojis.json"),
            exe.deletingLastPathComponent().appendingPathComponent("emojis.json"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Sources/EmojiKeycode/Resources/emojis.json"),
        ]
        for candidate in candidates where FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
        throw NSError(
            domain: "EmojiRepository",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "emojis.json not found in bundle"]
        )
    }

    func lookup(_ shortcode: String) -> String? {
        byShortcode[shortcode.lowercased()]
    }

    func search(prefix: String, limit: Int = 8) -> [EmojiMatch] {
        let p = prefix.lowercased()
        var results: [EmojiMatch] = []
        if p.isEmpty {
            for key in sortedShortcodes.prefix(limit) {
                if let emoji = byShortcode[key] {
                    results.append(EmojiMatch(shortcode: key, emoji: emoji))
                }
            }
            return results
        }

        var matches: [String] = []
        for key in sortedShortcodes where key.hasPrefix(p) {
            matches.append(key)
        }
        matches.sort { a, b in
            if a.count != b.count { return a.count < b.count }
            return a < b
        }
        for key in matches.prefix(limit) {
            if let emoji = byShortcode[key] {
                results.append(EmojiMatch(shortcode: key, emoji: emoji))
            }
        }
        return results
    }

    var shortcodeCount: Int { byShortcode.count }
}
