import Foundation

/// Normalizes both script text and speech output for comparison.
/// Handles numbers, abbreviations, homophones, and filler words.
enum TextNormalizer {

    // MARK: - Public API

    /// Full normalization pipeline for a single word.
    static func normalize(_ word: String) -> String {
        var result = word
            .lowercased()
            .trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        result = applyHomophone(result)
        return result
    }

    /// Normalize an entire string: expand numbers/abbreviations, filter fillers, normalize each word.
    static func normalizeText(_ text: String) -> [String] {
        let expanded = expandNumbers(text)
        let tokens = tokenize(expanded)
        return tokens
            .filter { !fillerWords.contains($0) }
            .map { normalize($0) }
            .filter { !$0.isEmpty }
    }

    /// Tokenize text into words.
    static func tokenize(_ text: String) -> [String] {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }

    // MARK: - Number Expansion

    static func expandNumbers(_ text: String) -> String {
        var result = text

        // Currency: $4.2M -> four point two million
        result = replaceCurrencyMatches(result)

        // Percentages: 23% -> twenty three percent
        result = replacePercentMatches(result)

        // Standalone numbers: 23 -> twenty three
        result = replaceStandaloneNumbers(result)

        // Quarter references: Q3 -> Q three
        result = replaceQuarterRefs(result)

        return result
    }

    // MARK: - Homophone Map

    private static let homophoneGroups: [[String]] = [
        ["their", "there", "theyre", "they're"],
        ["your", "youre", "you're"],
        ["its", "it's", "its"],
        ["to", "too", "two"],
        ["write", "right"],
        ["know", "no"],
        ["new", "knew"],
        ["hear", "here"],
        ["weather", "whether"],
        ["then", "than"],
        ["accept", "except"],
        ["affect", "effect"],
        ["were", "we're", "where"],
        ["brake", "break"],
        ["by", "buy", "bye"],
        ["cell", "sell"],
        ["peace", "piece"],
        ["wait", "weight"],
        ["weak", "week"],
        ["which", "witch"],
        ["one", "won"],
        ["for", "four", "fore"],
        ["ate", "eight"],
        ["sea", "see"],
        ["sun", "son"],
        ["would", "wood"],
        ["flour", "flower"],
        ["fair", "fare"],
        ["hole", "whole"],
        ["mail", "male"],
        ["meat", "meet"],
        ["pair", "pear", "pare"],
        ["plain", "plane"],
        ["principal", "principle"],
        ["role", "roll"],
        ["sight", "site", "cite"],
        ["stair", "stare"],
        ["steal", "steel"],
        ["tail", "tale"],
        ["thrown", "throne"],
        ["waste", "waist"],
        ["wear", "where", "ware"],
    ]

    private static let homophoneMap: [String: String] = {
        var map: [String: String] = [:]
        for group in homophoneGroups {
            let canonical = group[0]
            for word in group {
                let cleaned = word.replacingOccurrences(of: "'", with: "")
                map[cleaned] = canonical
            }
        }
        return map
    }()

    static func applyHomophone(_ word: String) -> String {
        let cleaned = word.replacingOccurrences(of: "'", with: "")
        return homophoneMap[cleaned] ?? word
    }

    // MARK: - Filler Words

    static let fillerWords: Set<String> = [
        "um", "uh", "uh", "like", "you know", "i mean",
        "basically", "actually", "literally", "right",
        "so", "well", "ok", "okay", "yeah",
    ]

    // MARK: - Number-to-Words Helpers

    private static let ones = [
        "", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
        "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
        "seventeen", "eighteen", "nineteen",
    ]

    private static let tens = [
        "", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety",
    ]

    static func numberToWords(_ n: Int) -> String {
        if n < 0 { return "negative \(numberToWords(-n))" }
        if n == 0 { return "zero" }
        if n < 20 { return ones[n] }
        if n < 100 {
            let remainder = n % 10
            return tens[n / 10] + (remainder > 0 ? " \(ones[remainder])" : "")
        }
        if n < 1000 {
            let remainder = n % 100
            return "\(ones[n / 100]) hundred" + (remainder > 0 ? " \(numberToWords(remainder))" : "")
        }
        if n < 1_000_000 {
            let thousands = n / 1000
            let remainder = n % 1000
            return "\(numberToWords(thousands)) thousand" + (remainder > 0 ? " \(numberToWords(remainder))" : "")
        }
        if n < 1_000_000_000 {
            let millions = n / 1_000_000
            let remainder = n % 1_000_000
            return "\(numberToWords(millions)) million" + (remainder > 0 ? " \(numberToWords(remainder))" : "")
        }
        let billions = n / 1_000_000_000
        let remainder = n % 1_000_000_000
        return "\(numberToWords(billions)) billion" + (remainder > 0 ? " \(numberToWords(remainder))" : "")
    }

    static func decimalToWords(_ value: Double) -> String {
        let intPart = Int(value)
        let fracPart = value - Double(intPart)
        if fracPart < 0.001 {
            return numberToWords(intPart)
        }
        // Express decimal: 4.2 -> "four point two"
        let fracString = String(format: "%.10g", fracPart).dropFirst(2) // drop "0."
        let fracWords = fracString.map { ones[Int(String($0)) ?? 0] }.joined(separator: " ")
        return "\(numberToWords(intPart)) point \(fracWords)"
    }

    // MARK: - Regex Replacement Helpers

    private static func replaceCurrencyMatches(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"\$(\d+(?:\.\d+)?)\s*([BMKbmk])"#) else { return text }
        var result = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let numRange = Range(match.range(at: 1), in: text),
                  let suffixRange = Range(match.range(at: 2), in: text) else { continue }
            let num = Double(text[numRange]) ?? 0
            let suffix = String(text[suffixRange]).uppercased()
            let suffixWord: String
            switch suffix {
            case "B": suffixWord = "billion"
            case "M": suffixWord = "million"
            case "K": suffixWord = "thousand"
            default: suffixWord = ""
            }
            let replacement = "\(decimalToWords(num)) \(suffixWord)"
            let fullRange = Range(match.range, in: text)!
            result = result.replacingCharacters(in: fullRange, with: replacement)
        }
        return result
    }

    private static func replacePercentMatches(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)%"#) else { return text }
        var result = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let numRange = Range(match.range(at: 1), in: text) else { continue }
            let num = Double(text[numRange]) ?? 0
            let replacement = "\(decimalToWords(num)) percent"
            let fullRange = Range(match.range, in: text)!
            result = result.replacingCharacters(in: fullRange, with: replacement)
        }
        return result
    }

    private static func replaceStandaloneNumbers(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"\b(\d+)\b"#) else { return text }
        var result = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let numRange = Range(match.range(at: 1), in: text) else { continue }
            let num = Int(text[numRange]) ?? 0
            let replacement = numberToWords(num)
            let fullRange = Range(match.range, in: text)!
            result = result.replacingCharacters(in: fullRange, with: replacement)
        }
        return result
    }

    private static func replaceQuarterRefs(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"\bQ(\d)\b"#, options: .caseInsensitive) else { return text }
        var result = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let digitRange = Range(match.range(at: 1), in: text) else { continue }
            let digit = Int(text[digitRange]) ?? 0
            let replacement = "Q \(numberToWords(digit))"
            let fullRange = Range(match.range, in: text)!
            result = result.replacingCharacters(in: fullRange, with: replacement)
        }
        return result
    }
}
