import Foundation

/// Unified content intake: converts various sources into engine-ready data.
enum ContentIngestor {

    /// Content ready for the engine to track.
    struct EngineContent {
        let scriptText: String
        let slideBoundaries: [Int]
        let source: ContentSource
        let sections: [ScriptSection]
    }

    /// Ingest a Presentation (from Chrome extension).
    static func ingest(_ presentation: Presentation) -> EngineContent {
        let sections = presentation.slides.map { slide in
            ScriptSection(
                index: slide.slideIndex,
                title: slide.slideTitle,
                text: slide.speakerNotes ?? ""
            )
        }
        return EngineContent(
            scriptText: presentation.fullScript,
            slideBoundaries: presentation.slideBoundaryWordIndices,
            source: .chromeExtension,
            sections: sections
        )
    }

    /// Ingest a Script (from manual entry or file).
    static func ingest(_ script: Script) -> EngineContent {
        EngineContent(
            scriptText: script.fullText,
            slideBoundaries: script.sectionBoundaryWordIndices,
            source: script.source,
            sections: script.sections
        )
    }

    /// Ingest a local file (markdown or plain text).
    static func ingestFile(at url: URL) throws -> EngineContent {
        let text = try String(contentsOf: url, encoding: .utf8)

        let script: Script
        if url.pathExtension.lowercased() == "md" {
            script = MarkdownParser.parse(text)
        } else {
            script = Script.fromPlainText(text, source: .localFile)
        }

        return ingest(script)
    }

    /// Ingest raw text (manual entry).
    static func ingestText(_ text: String) -> EngineContent {
        let script = Script.fromPlainText(text, source: .manual)
        return ingest(script)
    }
}
