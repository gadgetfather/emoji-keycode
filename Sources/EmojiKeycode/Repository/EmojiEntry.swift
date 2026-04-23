import Foundation

struct EmojiEntry: Decodable, Sendable {
    let emoji: String
    let names: [String]
    let tags: [String]
}
