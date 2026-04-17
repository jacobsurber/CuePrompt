import Foundation

/// Where content came from.
enum ContentSource: String, Codable, Sendable {
    case chromeExtension = "chrome_extension"
    case manual = "manual"
    case localFile = "local_file"
}
