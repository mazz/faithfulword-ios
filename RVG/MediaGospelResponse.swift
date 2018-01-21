import Foundation

public struct MediaGospelResponse: Codable {
    public var result: [MediaGospel]
    public var status: String
    public var version: String
}
