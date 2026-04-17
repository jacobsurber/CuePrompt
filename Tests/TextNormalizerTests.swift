import XCTest
@testable import CuePrompt

final class TextNormalizerTests: XCTestCase {

    // MARK: - Single Word Normalization

    func testBasicNormalization() {
        XCTAssertEqual(TextNormalizer.normalize("Hello"), "hello")
        XCTAssertEqual(TextNormalizer.normalize("WORLD"), "world")
    }

    func testPunctuationStripping() {
        XCTAssertEqual(TextNormalizer.normalize("hello,"), "hello")
        XCTAssertEqual(TextNormalizer.normalize("world!"), "world")
        XCTAssertEqual(TextNormalizer.normalize("(test)"), "test")
        XCTAssertEqual(TextNormalizer.normalize("\"quoted\""), "quoted")
    }

    func testWhitespaceStripping() {
        XCTAssertEqual(TextNormalizer.normalize("  hello  "), "hello")
        XCTAssertEqual(TextNormalizer.normalize("\thello\n"), "hello")
    }

    func testEmptyAndWhitespace() {
        XCTAssertEqual(TextNormalizer.normalize(""), "")
        XCTAssertEqual(TextNormalizer.normalize("   "), "")
    }

    // MARK: - Homophones

    func testHomophoneMapping() {
        // All members of a group map to the canonical (first) form
        XCTAssertEqual(TextNormalizer.normalize("there"), "their")
        XCTAssertEqual(TextNormalizer.normalize("they're"), "their")
        XCTAssertEqual(TextNormalizer.normalize("their"), "their")

        XCTAssertEqual(TextNormalizer.normalize("you're"), "your")
        XCTAssertEqual(TextNormalizer.normalize("youre"), "your")

        XCTAssertEqual(TextNormalizer.normalize("too"), "to")
        XCTAssertEqual(TextNormalizer.normalize("two"), "to")

        XCTAssertEqual(TextNormalizer.normalize("right"), "write")
        XCTAssertEqual(TextNormalizer.normalize("write"), "write")

        XCTAssertEqual(TextNormalizer.normalize("no"), "know")
        XCTAssertEqual(TextNormalizer.normalize("know"), "know")
    }

    func testHomophoneWithPunctuation() {
        // Punctuation stripped before homophone lookup
        XCTAssertEqual(TextNormalizer.normalize("there,"), "their")
        XCTAssertEqual(TextNormalizer.normalize("you're!"), "your")
    }

    func testNonHomophoneUnchanged() {
        XCTAssertEqual(TextNormalizer.normalize("elephant"), "elephant")
        XCTAssertEqual(TextNormalizer.normalize("revenue"), "revenue")
    }

    // MARK: - Number Expansion

    func testSmallNumbers() {
        XCTAssertEqual(TextNormalizer.numberToWords(0), "zero")
        XCTAssertEqual(TextNormalizer.numberToWords(1), "one")
        XCTAssertEqual(TextNormalizer.numberToWords(13), "thirteen")
        XCTAssertEqual(TextNormalizer.numberToWords(19), "nineteen")
    }

    func testTensNumbers() {
        XCTAssertEqual(TextNormalizer.numberToWords(20), "twenty")
        XCTAssertEqual(TextNormalizer.numberToWords(23), "twenty three")
        XCTAssertEqual(TextNormalizer.numberToWords(99), "ninety nine")
    }

    func testHundreds() {
        XCTAssertEqual(TextNormalizer.numberToWords(100), "one hundred")
        XCTAssertEqual(TextNormalizer.numberToWords(250), "two hundred fifty")
        XCTAssertEqual(TextNormalizer.numberToWords(999), "nine hundred ninety nine")
    }

    func testThousands() {
        XCTAssertEqual(TextNormalizer.numberToWords(1000), "one thousand")
        XCTAssertEqual(TextNormalizer.numberToWords(2500), "two thousand five hundred")
        XCTAssertEqual(TextNormalizer.numberToWords(10000), "ten thousand")
    }

    func testMillions() {
        XCTAssertEqual(TextNormalizer.numberToWords(1_000_000), "one million")
        XCTAssertEqual(TextNormalizer.numberToWords(4_200_000), "four million two hundred thousand")
    }

    func testBillions() {
        XCTAssertEqual(TextNormalizer.numberToWords(1_000_000_000), "one billion")
    }

    func testNegativeNumbers() {
        XCTAssertEqual(TextNormalizer.numberToWords(-5), "negative five")
    }

    func testDecimalToWords() {
        XCTAssertEqual(TextNormalizer.decimalToWords(4.2), "four point two")
        XCTAssertEqual(TextNormalizer.decimalToWords(3.0), "three")
        XCTAssertEqual(TextNormalizer.decimalToWords(0.5), "zero point five")
    }

    // MARK: - Full Text Expansion

    func testExpandStandaloneNumbers() {
        let result = TextNormalizer.expandNumbers("We grew 23 percent")
        XCTAssertTrue(result.contains("twenty three"), "Got: \(result)")
    }

    func testExpandPercentage() {
        let result = TextNormalizer.expandNumbers("Revenue up 15%")
        XCTAssertTrue(result.contains("fifteen") && result.contains("percent"), "Got: \(result)")
    }

    func testExpandCurrency() {
        let result = TextNormalizer.expandNumbers("$4.2M in revenue")
        XCTAssertTrue(result.contains("four") && result.contains("million"), "Got: \(result)")
    }

    func testExpandCurrencyBillion() {
        let result = TextNormalizer.expandNumbers("$1.5B market")
        XCTAssertTrue(result.contains("one") && result.contains("billion"), "Got: \(result)")
    }

    func testExpandQuarterRef() {
        let result = TextNormalizer.expandNumbers("In Q3 we shipped")
        XCTAssertTrue(result.contains("three"), "Got: \(result)")
    }

    // MARK: - Full Pipeline (normalizeText)

    func testNormalizeTextBasic() {
        let result = TextNormalizer.normalizeText("Hello World")
        XCTAssertEqual(result, ["hello", "world"])
    }

    func testNormalizeTextFiltersFillers() {
        let result = TextNormalizer.normalizeText("um hello uh world")
        XCTAssertEqual(result, ["hello", "world"])
    }

    func testNormalizeTextWithNumbers() {
        let result = TextNormalizer.normalizeText("We have 23 users")
        XCTAssertTrue(result.contains("twenty"))
        XCTAssertTrue(result.contains("three"))
        XCTAssertTrue(result.contains("users"))
    }

    func testNormalizeTextWithHomophones() {
        let result = TextNormalizer.normalizeText("They're going there")
        // Both "they're" and "there" -> "their"
        XCTAssertEqual(result.filter { $0 == "their" }.count, 2)
    }

    func testNormalizeTextEmpty() {
        XCTAssertEqual(TextNormalizer.normalizeText(""), [])
        XCTAssertEqual(TextNormalizer.normalizeText("   "), [])
    }

    func testNormalizeTextOnlyFillers() {
        let result = TextNormalizer.normalizeText("um uh like")
        XCTAssertEqual(result, [])
    }

    // MARK: - Tokenize

    func testTokenize() {
        XCTAssertEqual(TextNormalizer.tokenize("hello world"), ["hello", "world"])
        XCTAssertEqual(TextNormalizer.tokenize("  hello   world  "), ["hello", "world"])
        XCTAssertEqual(TextNormalizer.tokenize(""), [])
    }
}
