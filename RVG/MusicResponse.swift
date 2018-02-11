
import Foundation

public struct MusicResponse: Codable {
    public var result: [Music]
    public var status: String
    public var version: String
}

