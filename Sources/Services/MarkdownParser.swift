import Foundation

/// Parses markdown text into script sections.
/// Headers (#, ##) become section markers. Text between headers becomes section content.
enum MarkdownParser {

    static func parse(_ text: String) -> Script {
        let lines = text.components(separatedBy: .newlines)
        var sections: [ScriptSection] = []
        var currentTitle: String?
        var currentLines: [String] = []
        var sectionIndex = 0

        for line in lines {
            if let headerTitle = extractHeader(line) {
                // Save previous section
                if !currentLines.isEmpty || currentTitle != nil {
                    let sectionText = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !sectionText.isEmpty {
                        sections.append(ScriptSection(
                            index: sectionIndex,
                            title: currentTitle,
                            text: sectionText
                        ))
                        sectionIndex += 1
                    }
                    currentLines = []
                }
                currentTitle = headerTitle
            } else {
                currentLines.append(line)
            }
        }

        // Save final section
        let finalText = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalText.isEmpty {
            sections.append(ScriptSection(
                index: sectionIndex,
                title: currentTitle,
                text: finalText
            ))
        }

        // If no headers found, treat double newlines as section breaks
        if sections.isEmpty {
            return Script.fromPlainText(text, source: .localFile)
        }

        let fullText = sections.map(\.text).joined(separator: "\n\n")
        return Script(text: fullText, sections: sections, source: .localFile)
    }

    private static func extractHeader(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("# ") {
            return String(trimmed.dropFirst(2))
        }
        if trimmed.hasPrefix("## ") {
            return String(trimmed.dropFirst(3))
        }
        if trimmed.hasPrefix("### ") {
            return String(trimmed.dropFirst(4))
        }
        return nil
    }
}
