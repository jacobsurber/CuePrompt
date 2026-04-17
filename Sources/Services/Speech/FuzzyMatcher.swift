import Foundation

/// Jaro-Winkler string similarity for short-word matching.
enum FuzzyMatcher {

    /// Returns similarity between 0.0 (no match) and 1.0 (exact match).
    static func similarity(_ a: String, _ b: String) -> Double {
        if a.isEmpty || b.isEmpty { return 0.0 }
        if a == b { return 1.0 }

        let aChars = Array(a)
        let bChars = Array(b)
        let matchDistance = max(aChars.count, bChars.count) / 2 - 1

        guard matchDistance >= 0 else {
            return a == b ? 1.0 : 0.0
        }

        var aMatched = [Bool](repeating: false, count: aChars.count)
        var bMatched = [Bool](repeating: false, count: bChars.count)

        var matches: Double = 0
        var transpositions: Double = 0

        for i in aChars.indices {
            let start = max(0, i - matchDistance)
            let end = min(i + matchDistance + 1, bChars.count)
            guard start < end else { continue }
            for j in start..<end {
                guard !bMatched[j], aChars[i] == bChars[j] else { continue }
                aMatched[i] = true
                bMatched[j] = true
                matches += 1
                break
            }
        }

        guard matches > 0 else { return 0.0 }

        var k = 0
        for i in aChars.indices {
            guard aMatched[i] else { continue }
            while !bMatched[k] { k += 1 }
            if aChars[i] != bChars[k] { transpositions += 1 }
            k += 1
        }

        let jaro = (matches / Double(aChars.count)
            + matches / Double(bChars.count)
            + (matches - transpositions / 2) / matches) / 3

        // Winkler boost for common prefix (up to 4 chars)
        var prefix = 0
        for i in 0..<min(4, min(aChars.count, bChars.count)) {
            if aChars[i] == bChars[i] { prefix += 1 } else { break }
        }

        return jaro + Double(prefix) * 0.1 * (1 - jaro)
    }
}
