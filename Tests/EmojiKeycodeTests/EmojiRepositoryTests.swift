import XCTest
@testable import EmojiKeycode

final class EmojiRepositoryTests: XCTestCase {
    private func makeRepo() -> EmojiRepository {
        let entries: [EmojiEntry] = [
            EmojiEntry(emoji: "❤️", names: ["heart"], tags: ["love"]),
            EmojiEntry(emoji: "😄", names: ["smile"], tags: ["happy"]),
            EmojiEntry(emoji: "😏", names: ["smirk"], tags: []),
            EmojiEntry(emoji: "🛩️", names: ["small_airplane"], tags: []),
            EmojiEntry(emoji: "👍", names: ["+1", "thumbsup"], tags: []),
            EmojiEntry(emoji: "👨‍👩‍👧", names: ["family_man_woman_girl"], tags: []),
        ]
        return EmojiRepository(entries: entries)
    }

    func testLookupExact() {
        XCTAssertEqual(makeRepo().lookup("heart"), "❤️")
    }

    func testLookupCaseInsensitive() {
        XCTAssertEqual(makeRepo().lookup("HEART"), "❤️")
        XCTAssertEqual(makeRepo().lookup("Smile"), "😄")
    }

    func testLookupMiss() {
        XCTAssertNil(makeRepo().lookup("nope"))
    }

    func testLookupAlias() {
        XCTAssertEqual(makeRepo().lookup("+1"), "👍")
        XCTAssertEqual(makeRepo().lookup("thumbsup"), "👍")
    }

    func testSearchPrefix() {
        let results = makeRepo().search(prefix: "sm", limit: 8)
        let codes = results.map { $0.shortcode }
        XCTAssertTrue(codes.contains("smile"))
        XCTAssertTrue(codes.contains("smirk"))
        XCTAssertTrue(codes.contains("small_airplane"))
        XCTAssertEqual(codes.first, "smile")
        XCTAssertTrue(codes.firstIndex(of: "smile")! < codes.firstIndex(of: "small_airplane")!)
    }

    func testSearchEmptyReturnsSomething() {
        XCTAssertFalse(makeRepo().search(prefix: "", limit: 3).isEmpty)
    }

    func testZWJEntryPresent() {
        let emoji = makeRepo().lookup("family_man_woman_girl")
        XCTAssertNotNil(emoji)
        XCTAssertGreaterThan(emoji!.utf16.count, 3)
    }

    func testSearchLimit() {
        let results = makeRepo().search(prefix: "", limit: 2)
        XCTAssertEqual(results.count, 2)
    }
}
