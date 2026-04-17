import XCTest
@testable import CuePrompt

final class ContentIngestorTests: XCTestCase {

    func testIngestText() {
        let content = ContentIngestor.ingestText("Hello world this is a test")
        XCTAssertEqual(content.source, .manual)
        XCTAssertFalse(content.scriptText.isEmpty)
    }

    func testIngestPresentation() {
        let slides = [
            Slide(slideIndex: 0, speakerNotes: "First slide notes", slideTitle: "Intro", thumbnailPath: nil),
            Slide(slideIndex: 1, speakerNotes: "Second slide notes", slideTitle: "Body", thumbnailPath: nil),
        ]
        let presentation = Presentation(slides: slides, title: "Test", source: .chromeExtension)

        let content = ContentIngestor.ingest(presentation)
        XCTAssertEqual(content.source, .chromeExtension)
        XCTAssertTrue(content.scriptText.contains("First slide notes"))
        XCTAssertTrue(content.scriptText.contains("Second slide notes"))
        XCTAssertEqual(content.slideBoundaries.count, 2)
    }

    func testIngestPresentationSlideBoundaries() {
        let slides = [
            Slide(slideIndex: 0, speakerNotes: "one two three", slideTitle: nil, thumbnailPath: nil),
            Slide(slideIndex: 1, speakerNotes: "four five", slideTitle: nil, thumbnailPath: nil),
            Slide(slideIndex: 2, speakerNotes: "six", slideTitle: nil, thumbnailPath: nil),
        ]
        let presentation = Presentation(slides: slides, title: nil, source: .chromeExtension)

        let content = ContentIngestor.ingest(presentation)
        // Boundaries are cumulative word counts at end of each slide
        XCTAssertEqual(content.slideBoundaries.count, 3)
        XCTAssertEqual(content.slideBoundaries[0], 3) // "one two three" = 3 words
        XCTAssertEqual(content.slideBoundaries[1], 5) // + "four five" = 5
        XCTAssertEqual(content.slideBoundaries[2], 6) // + "six" = 6
    }

    func testIngestScript() {
        let section = ScriptSection(index: 0, title: "Test", text: "Hello world")
        let script = Script(text: "Hello world", sections: [section], source: .localFile)

        let content = ContentIngestor.ingest(script)
        XCTAssertEqual(content.source, .localFile)
        XCTAssertEqual(content.scriptText, "Hello world")
    }

    func testIngestEmptyText() {
        let content = ContentIngestor.ingestText("")
        XCTAssertTrue(content.scriptText.isEmpty)
    }
}
