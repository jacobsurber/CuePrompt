import XCTest
@testable import CuePrompt

final class FuzzyMatcherTests: XCTestCase {

    // MARK: - Exact Matches

    func testIdenticalStrings() {
        XCTAssertEqual(FuzzyMatcher.similarity("hello", "hello"), 1.0)
        XCTAssertEqual(FuzzyMatcher.similarity("a", "a"), 1.0)
    }

    func testEmptyStrings() {
        XCTAssertEqual(FuzzyMatcher.similarity("", ""), 0.0)
        XCTAssertEqual(FuzzyMatcher.similarity("hello", ""), 0.0)
        XCTAssertEqual(FuzzyMatcher.similarity("", "hello"), 0.0)
    }

    // MARK: - High Similarity

    func testSimilarWords() {
        // Typical speech recognition near-misses
        let score1 = FuzzyMatcher.similarity("revenue", "revenues")
        XCTAssertGreaterThan(score1, 0.9, "revenue vs revenues should be very similar")

        let score2 = FuzzyMatcher.similarity("growth", "groth")
        XCTAssertGreaterThan(score2, 0.85, "growth vs groth (typo) should be similar")

        let score3 = FuzzyMatcher.similarity("million", "millions")
        XCTAssertGreaterThan(score3, 0.9, "million vs millions should be very similar")
    }

    func testSingleCharDifference() {
        let score = FuzzyMatcher.similarity("cat", "car")
        XCTAssertGreaterThan(score, 0.7)
        XCTAssertLessThan(score, 1.0)
    }

    // MARK: - Low Similarity

    func testCompletelyDifferent() {
        let score = FuzzyMatcher.similarity("abc", "xyz")
        XCTAssertEqual(score, 0.0)
    }

    func testVeryDifferent() {
        let score = FuzzyMatcher.similarity("hello", "world")
        XCTAssertLessThan(score, 0.5)
    }

    // MARK: - Symmetry

    func testSymmetric() {
        let ab = FuzzyMatcher.similarity("hello", "hallo")
        let ba = FuzzyMatcher.similarity("hallo", "hello")
        XCTAssertEqual(ab, ba, accuracy: 0.001)
    }

    // MARK: - Winkler Prefix Boost

    func testPrefixBoost() {
        // Same Jaro distance but different prefix overlap -> Winkler boost
        let withPrefix = FuzzyMatcher.similarity("abcxyz", "abcxzz")
        let noPrefix = FuzzyMatcher.similarity("xyzabc", "xzzabc")
        // withPrefix should be >= noPrefix due to common prefix boost
        XCTAssertGreaterThanOrEqual(withPrefix, noPrefix)
    }

    // MARK: - Single Character

    func testSingleCharStrings() {
        XCTAssertEqual(FuzzyMatcher.similarity("a", "a"), 1.0)
        XCTAssertEqual(FuzzyMatcher.similarity("a", "b"), 0.0)
    }

    // MARK: - Speech Recognition Scenarios

    func testCommonMisrecognitions() {
        // "percent" misheard as "per cent"
        let score1 = FuzzyMatcher.similarity("percent", "persent")
        XCTAssertGreaterThan(score1, 0.85)

        // "quarterly" misheard as "quarterly" (same) — sanity
        XCTAssertEqual(FuzzyMatcher.similarity("quarterly", "quarterly"), 1.0)

        // "presentation" vs "presentations"
        let score2 = FuzzyMatcher.similarity("presentation", "presentations")
        XCTAssertGreaterThan(score2, 0.95)
    }

    // MARK: - Length Disparity

    func testVeryDifferentLengths() {
        let score = FuzzyMatcher.similarity("a", "abcdefghij")
        XCTAssertLessThan(score, 0.8, "Very different lengths should score low")
    }
}
