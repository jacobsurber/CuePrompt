import Foundation

/// A freeform script for prompting, not tied to slides.
/// Created from manual text entry or local file import.
struct Script: Codable, Sendable {
    var text: String
    var sections: [ScriptSection]
    var source: ContentSource

    /// Full text for the engine.
    var fullText: String { text }

    /// Word indices where each section boundary occurs.
    var sectionBoundaryWordIndices: [Int] {
        var indices: [Int] = []
        var wordCount = 0
        for section in sections {
            let words = section.text.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            wordCount += words.count
            indices.append(wordCount)
        }
        return indices
    }

    /// Create from raw text, splitting on double newlines.
    static func fromPlainText(_ text: String, source: ContentSource = .manual) -> Script {
        let parts = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let sections = parts.enumerated().map { i, part in
            ScriptSection(index: i, title: nil, text: part)
        }

        return Script(text: text, sections: sections, source: source)
    }
}

/// A section within a script (analogous to a slide).
struct ScriptSection: Codable, Sendable, Identifiable {
    var id: Int { index }
    let index: Int
    var title: String?
    var text: String
}
