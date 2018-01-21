import Foundation

public struct MediaMusicResponse: Codable {
    public var result: [MediaMusic]
    public var status: String
    public var version: String
}
