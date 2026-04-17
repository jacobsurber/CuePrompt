import XCTest
@testable import CuePrompt

final class MarkdownParserTests: XCTestCase {

    func testParseWithH1Headers() {
        let md = """
        # Introduction
        Welcome to the presentation.

        # Main Points
        Here are the key takeaways.

        # Conclusion
        Thank you for listening.
        """

        let script = MarkdownParser.parse(md)
        XCTAssertEqual(script.sections.count, 3)
        XCTAssertEqual(script.sections[0].title, "Introduction")
        XCTAssertTrue(script.sections[0].text.contains("Welcome"))
        XCTAssertEqual(script.sections[1].title, "Main Points")
        XCTAssertEqual(script.sections[2].title, "Conclusion")
    }

    func testParseWithH2Headers() {
        let md = """
        ## First Section
        Some content here.

        ## Second Section
        More content here.
        """

        let script = MarkdownParser.parse(md)
        XCTAssertEqual(script.sections.count, 2)
        XCTAssertEqual(script.sections[0].title, "First Section")
    }

    func testParseWithH3Headers() {
        let md = """
        ### Deep Section
        Content under a level-3 header.
        """

        let script = MarkdownParser.parse(md)
        XCTAssertEqual(script.sections.count, 1)
        XCTAssertEqual(script.sections[0].title, "Deep Section")
    }

    func testParseWithMixedHeaders() {
        let md = """
        # Title
        Intro text.

        ## Subtitle
        Body text.

        ### Sub-subtitle
        Detail text.
        """

        let script = MarkdownParser.parse(md)
        XCTAssertEqual(script.sections.count, 3)
    }

    func testParseNoHeaders() {
        let md = """
        Just plain text without any headers.

        Another paragraph of text.
        """

        let script = MarkdownParser.parse(md)
        // Should fall back to plain text parsing (double newlines as breaks)
        XCTAssertFalse(script.fullText.isEmpty)
    }

    func testParseEmptyText() {
        let script = MarkdownParser.parse("")
        XCTAssertTrue(script.fullText.isEmpty)
    }

    func testParseHeaderWithNoContent() {
        let md = """
        # Empty Section

        # Section With Content
        This has content.
        """

        let script = MarkdownParser.parse(md)
        // Empty section is skipped
        XCTAssertEqual(script.sections.count, 1)
        XCTAssertEqual(script.sections[0].title, "Section With Content")
    }

    func testParseContentBeforeFirstHeader() {
        let md = """
        Some introductory text before any header.

        # First Real Section
        Content here.
        """

        let script = MarkdownParser.parse(md)
        XCTAssertEqual(script.sections.count, 2)
        // First section has no title (text before first header)
        XCTAssertNil(script.sections[0].title)
        XCTAssertTrue(script.sections[0].text.contains("introductory"))
        XCTAssertEqual(script.sections[1].title, "First Real Section")
    }

    func testParseSectionIndicesAreSequential() {
        let md = """
        # One
        text

        # Two
        text

        # Three
        text
        """

        let script = MarkdownParser.parse(md)
        for (i, section) in script.sections.enumerated() {
            XCTAssertEqual(section.index, i)
        }
    }

    func testParseFullTextJoinsSections() {
        let md = """
        # A
        First section.

        # B
        Second section.
        """

        let script = MarkdownParser.parse(md)
        XCTAssertTrue(script.fullText.contains("First section."))
        XCTAssertTrue(script.fullText.contains("Second section."))
    }

    func testParseSourceIsLocalFile() {
        let script = MarkdownParser.parse("# Test\nContent")
        XCTAssertEqual(script.source, .localFile)
    }
}
