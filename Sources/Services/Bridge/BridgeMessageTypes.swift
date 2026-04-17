import Foundation

/// Messages received from the Chrome extension over WebSocket.
enum BridgeMessage: Codable {
    case slideUpdate(SlideUpdateMessage)
    case fullSync(FullSyncMessage)
    case disconnect

    enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "slideUpdate":
            self = .slideUpdate(try SlideUpdateMessage(from: decoder))
        case "fullSync":
            self = .fullSync(try FullSyncMessage(from: decoder))
        case "disconnect":
            self = .disconnect
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [CodingKeys.type], debugDescription: "Unknown type: \(type)")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .slideUpdate(let msg):
            try container.encode("slideUpdate", forKey: .type)
            try msg.encode(to: encoder)
        case .fullSync(let msg):
            try container.encode("fullSync", forKey: .type)
            try msg.encode(to: encoder)
        case .disconnect:
            try container.encode("disconnect", forKey: .type)
        }
    }
}

struct SlideUpdateMessage: Codable {
    let slideIndex: Int
    let totalSlides: Int
    let speakerNotes: String?
    let slideTitle: String?
    let thumbnailDataURL: String?
}

struct FullSyncMessage: Codable {
    let slides: [SyncSlide]
}

struct SyncSlide: Codable {
    let slideIndex: Int
    let speakerNotes: String?
    let slideTitle: String?
    let thumbnailDataURL: String?
}
