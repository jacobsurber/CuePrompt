import Foundation

/// A presentation with slides, typically sourced from the Chrome extension.
struct Presentation: Codable, Sendable {
    var slides: [Slide]
    var title: String?
    var source: ContentSource

    var totalSlides: Int { slides.count }

    /// Full script text from all slides' speaker notes concatenated.
    var fullScript: String {
        slides.compactMap(\.speakerNotes).joined(separator: "\n\n")
    }

    /// Word indices where each slide boundary occurs in the full script.
    var slideBoundaryWordIndices: [Int] {
        var indices: [Int] = []
        var wordCount = 0
        for slide in slides {
            if let notes = slide.speakerNotes {
                let words = notes.components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }
                wordCount += words.count
                indices.append(wordCount)
            }
        }
        return indices
    }
}

/// A single slide within a presentation.
struct Slide: Codable, Sendable, Identifiable {
    var id: Int { slideIndex }
    let slideIndex: Int
    var speakerNotes: String?
    var slideTitle: String?
    var thumbnailPath: String? // Path to thumbnail image file on disk
}
