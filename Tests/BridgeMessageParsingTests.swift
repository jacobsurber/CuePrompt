import XCTest
@testable import CuePrompt

final class BridgeMessageParsingTests: XCTestCase {

    // MARK: - fullSync

    func testDecodeFullSync() throws {
        let json = """
        {
          "type": "fullSync",
          "slides": [
            { "slideIndex": 0, "speakerNotes": "Hello world", "slideTitle": "Intro" },
            { "slideIndex": 1, "speakerNotes": "Second slide", "slideTitle": "Body" }
          ]
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(BridgeMessage.self, from: json)
        if case .fullSync(let sync) = message {
            XCTAssertEqual(sync.slides.count, 2)
            XCTAssertEqual(sync.slides[0].slideIndex, 0)
            XCTAssertEqual(sync.slides[0].speakerNotes, "Hello world")
            XCTAssertEqual(sync.slides[1].slideTitle, "Body")
        } else {
            XCTFail("Expected fullSync, got \(message)")
        }
    }

    func testDecodeFullSyncWithNulls() throws {
        let json = """
        {
          "type": "fullSync",
          "slides": [
            { "slideIndex": 0, "speakerNotes": null, "slideTitle": null }
          ]
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(BridgeMessage.self, from: json)
        if case .fullSync(let sync) = message {
            XCTAssertNil(sync.slides[0].speakerNotes)
            XCTAssertNil(sync.slides[0].slideTitle)
        } else {
            XCTFail("Expected fullSync")
        }
    }

    // MARK: - slideUpdate

    func testDecodeSlideUpdate() throws {
        let json = """
        {
          "type": "slideUpdate",
          "slideIndex": 3,
          "totalSlides": 12,
          "speakerNotes": "Now let's talk about revenue",
          "slideTitle": "Revenue"
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(BridgeMessage.self, from: json)
        if case .slideUpdate(let update) = message {
            XCTAssertEqual(update.slideIndex, 3)
            XCTAssertEqual(update.totalSlides, 12)
            XCTAssertEqual(update.speakerNotes, "Now let's talk about revenue")
            XCTAssertEqual(update.slideTitle, "Revenue")
        } else {
            XCTFail("Expected slideUpdate")
        }
    }

    func testDecodeSlideUpdateMinimalFields() throws {
        let json = """
        {
          "type": "slideUpdate",
          "slideIndex": 0,
          "totalSlides": 5
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(BridgeMessage.self, from: json)
        if case .slideUpdate(let update) = message {
            XCTAssertEqual(update.slideIndex, 0)
            XCTAssertNil(update.speakerNotes)
        } else {
            XCTFail("Expected slideUpdate")
        }
    }

    // MARK: - disconnect

    func testDecodeDisconnect() throws {
        let json = """
        { "type": "disconnect" }
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(BridgeMessage.self, from: json)
        if case .disconnect = message {
            // pass
        } else {
            XCTFail("Expected disconnect")
        }
    }

    // MARK: - Error cases

    func testDecodeUnknownType() {
        let json = """
        { "type": "unknown" }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(BridgeMessage.self, from: json))
    }

    func testDecodeMissingType() {
        let json = """
        { "slideIndex": 0 }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(BridgeMessage.self, from: json))
    }

    // MARK: - Round-trip encode/decode

    func testRoundTripSlideUpdate() throws {
        let original = BridgeMessage.slideUpdate(SlideUpdateMessage(
            slideIndex: 5,
            totalSlides: 10,
            speakerNotes: "Test notes",
            slideTitle: "Test",
            thumbnailDataURL: nil
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BridgeMessage.self, from: data)

        if case .slideUpdate(let update) = decoded {
            XCTAssertEqual(update.slideIndex, 5)
            XCTAssertEqual(update.speakerNotes, "Test notes")
        } else {
            XCTFail("Round-trip failed")
        }
    }

    func testRoundTripDisconnect() throws {
        let original = BridgeMessage.disconnect
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BridgeMessage.self, from: data)

        if case .disconnect = decoded {
            // pass
        } else {
            XCTFail("Round-trip failed")
        }
    }

    // MARK: - Full fixture-style message

    func testDecodeFullFixtureMessage() throws {
        let json = """
        {
          "type": "fullSync",
          "slides": [
            { "slideIndex": 0, "speakerNotes": "Welcome everyone.", "slideTitle": "Q3 Revenue Growth" },
            { "slideIndex": 1, "speakerNotes": "Revenue increased 23%.", "slideTitle": "Revenue Overview" },
            { "slideIndex": 2, "speakerNotes": "Enterprise grew 45%.", "slideTitle": "Enterprise Growth" },
            { "slideIndex": 3, "speakerNotes": null, "slideTitle": "Thank You" }
          ]
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(BridgeMessage.self, from: json)
        if case .fullSync(let sync) = message {
            XCTAssertEqual(sync.slides.count, 4)
            XCTAssertEqual(sync.slides[2].slideTitle, "Enterprise Growth")
            XCTAssertNil(sync.slides[3].speakerNotes)
        } else {
            XCTFail("Expected fullSync")
        }
    }
}
