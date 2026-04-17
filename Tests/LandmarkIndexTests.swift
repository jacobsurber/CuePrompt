import XCTest
@testable import CuePrompt

final class LandmarkIndexTests: XCTestCase {

    // MARK: - Basic Construction

    func testEmptyScript() {
        let index = LandmarkIndex(scriptText: "")
        XCTAssertEqual(index.wordCount, 0)
        XCTAssertEqual(index.normalizedWords, [])
    }

    func testSingleWord() {
        let index = LandmarkIndex(scriptText: "Hello")
        XCTAssertEqual(index.wordCount, 1)
        XCTAssertEqual(index.normalizedWords, ["hello"])
    }

    func testMultipleWords() {
        let index = LandmarkIndex(scriptText: "Our revenue grew significantly last quarter")
        XCTAssertEqual(index.wordCount, 6)
    }

    func testNormalizesWords() {
        let index = LandmarkIndex(scriptText: "Hello, World!")
        XCTAssertEqual(index.normalizedWords, ["hello", "world"])
    }

    func testFiltersFillerWords() {
        let index = LandmarkIndex(scriptText: "um hello uh world")
        XCTAssertEqual(index.normalizedWords, ["hello", "world"])
    }

    // MARK: - Exact Trigram Matching

    func testExactTrigramMatch() {
        let script = "Our revenue grew significantly last quarter and we expect continued growth"
        let index = LandmarkIndex(scriptText: script)

        let matches = index.findLandmarks(
            spokenWords: ["revenue", "grew", "significantly"],
            searchRange: 0..<index.wordCount
        )

        XCTAssertFalse(matches.isEmpty, "Should find exact trigram match")
        let best = matches.max(by: { $0.score < $1.score })!
        XCTAssertEqual(best.length, 3)
        XCTAssertEqual(best.score, 1.0)
    }

    func testExactTrigramPositionCorrect() {
        let script = "first second revenue grew significantly last word"
        let index = LandmarkIndex(scriptText: script)

        let matches = index.findLandmarks(
            spokenWords: ["revenue", "grew", "significantly"],
            searchRange: 0..<index.wordCount
        )

        XCTAssertFalse(matches.isEmpty)
        // "revenue" is at index 2 after normalization (first=0, second=1, revenue=2)
        let best = matches.first!
        XCTAssertEqual(best.scriptWordIndex, 2)
    }

    // MARK: - Exact Bigram Matching

    func testExactBigramMatch() {
        let script = "Our quarterly earnings exceeded expectations this year"
        let index = LandmarkIndex(scriptText: script)

        let matches = index.findLandmarks(
            spokenWords: ["quarterly", "earnings"],
            searchRange: 0..<index.wordCount
        )

        XCTAssertFalse(matches.isEmpty, "Should find exact bigram match")
        let best = matches.first!
        XCTAssertEqual(best.length, 2)
    }

    func testCommonBigramsExcluded() {
        // "in the" is a common bigram and should be excluded from exact matching
        let script = "We are in the market for growth"
        let index = LandmarkIndex(scriptText: script)

        let matches = index.findLandmarks(
            spokenWords: ["in", "the"],
            searchRange: 0..<index.wordCount
        )

        // Should find no exact bigram match (common phrase excluded)
        let exactBigrams = matches.filter { $0.length == 2 && $0.score == 1.0 }
        XCTAssertTrue(exactBigrams.isEmpty, "Common bigrams should be excluded from exact index")
    }

    // MARK: - Search Range Filtering

    func testSearchRangeFilters() {
        let script = "revenue grew significantly in Q1 and revenue grew significantly in Q2"
        let index = LandmarkIndex(scriptText: script)

        // Search only the second half
        let midpoint = index.wordCount / 2
        let matches = index.findLandmarks(
            spokenWords: ["revenue", "grew", "significantly"],
            searchRange: midpoint..<index.wordCount
        )

        // Should find the second occurrence, not the first
        XCTAssertFalse(matches.isEmpty)
        for match in matches {
            XCTAssertGreaterThanOrEqual(match.scriptWordIndex, midpoint)
        }
    }

    func testEmptySearchRange() {
        let script = "revenue grew significantly"
        let index = LandmarkIndex(scriptText: script)

        let matches = index.findLandmarks(
            spokenWords: ["revenue", "grew", "significantly"],
            searchRange: 0..<0
        )

        XCTAssertTrue(matches.isEmpty)
    }

    // MARK: - Fuzzy Matching Fallback

    func testFuzzyMatchOnSimilarWords() {
        let script = "Our presentation highlights the quarterly achievements"
        let index = LandmarkIndex(scriptText: script)

        // "presentations" (plural) vs "presentation" (singular) — fuzzy should catch this
        let matches = index.findLandmarks(
            spokenWords: ["presentations", "highlights"],
            searchRange: 0..<index.wordCount
        )

        XCTAssertFalse(matches.isEmpty, "Fuzzy matching should find close matches")
    }

    // MARK: - No Match Scenarios

    func testNoMatchForUnrelatedWords() {
        let script = "Our revenue grew significantly last quarter"
        let index = LandmarkIndex(scriptText: script)

        let matches = index.findLandmarks(
            spokenWords: ["elephant", "bicycle", "umbrella"],
            searchRange: 0..<index.wordCount
        )

        // No strong or weak matches expected
        let strong = matches.filter { $0.isStrong() }
        XCTAssertTrue(strong.isEmpty, "Unrelated words should not produce strong matches")
    }

    func testSingleWordNotEnough() {
        let script = "Our revenue grew significantly"
        let index = LandmarkIndex(scriptText: script)

        let matches = index.findLandmarks(
            spokenWords: ["revenue"],
            searchRange: 0..<index.wordCount
        )

        // Need at least 2 words for landmarks
        XCTAssertTrue(matches.isEmpty)
    }

    // MARK: - Number Normalization

    func testNumbersNormalized() {
        let script = "We grew 23 percent last year"
        let index = LandmarkIndex(scriptText: script)

        // Speech recognizer might output "twenty three" or we pass raw text
        // The script "23" should be normalized to "twenty three" in the index
        XCTAssertTrue(index.normalizedWords.contains("twenty"))
        XCTAssertTrue(index.normalizedWords.contains("three"))
    }
}
