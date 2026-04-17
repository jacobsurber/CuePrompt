import XCTest
@testable import CuePrompt

final class AppSettingsTests: XCTestCase {

    func testDefaultValues() {
        let settings = AppSettings()
        XCTAssertEqual(settings.fontSize, 28)
        XCTAssertEqual(settings.fontName, "SF Pro")
        XCTAssertEqual(settings.textOpacity, 0.4)
        XCTAssertEqual(settings.countdownDuration, 3)
        XCTAssertTrue(settings.autoExpandOnStart)
        XCTAssertTrue(settings.collapseOnFinish)
        XCTAssertEqual(settings.thumbnailPosition, .right)
    }

    func testEncodeDecode() throws {
        var settings = AppSettings()
        settings.fontSize = 42
        settings.preferredModel = "openai_whisper-large-v3"
        settings.thumbnailPosition = .left

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded.fontSize, 42)
        XCTAssertEqual(decoded.preferredModel, "openai_whisper-large-v3")
        XCTAssertEqual(decoded.thumbnailPosition, .left)
    }

    func testDecodeMissingKeysUsesDefaults() throws {
        // Simulate a saved settings file from an older version with fewer keys
        let json = """
        { "fontSize": 32, "fontName": "Helvetica" }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AppSettings.self, from: json)
        XCTAssertEqual(decoded.fontSize, 32)
        XCTAssertEqual(decoded.fontName, "Helvetica")
        // Missing keys should use defaults
        XCTAssertEqual(decoded.textOpacity, 0.4)
        XCTAssertEqual(decoded.countdownDuration, 3)
        XCTAssertTrue(decoded.autoExpandOnStart)
        XCTAssertEqual(decoded.preferredProvider, "WhisperKit")
    }

    func testDecodeEmptyObject() throws {
        let json = "{}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppSettings.self, from: json)
        // Everything should be defaults
        XCTAssertEqual(decoded.fontSize, 28)
        XCTAssertEqual(decoded.expandedWidth, 800)
    }

    func testDecodeWithExtraKeys() throws {
        // Future versions might add keys; old decoder shouldn't crash
        let json = """
        { "fontSize": 28, "futureFeatureFlag": true, "newSetting": "hello" }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AppSettings.self, from: json)
        XCTAssertEqual(decoded.fontSize, 28)
    }

    func testThumbnailPositionCodable() throws {
        let left = AppSettings.ThumbnailPosition.left
        let data = try JSONEncoder().encode(left)
        let decoded = try JSONDecoder().decode(AppSettings.ThumbnailPosition.self, from: data)
        XCTAssertEqual(decoded, .left)
    }
}
