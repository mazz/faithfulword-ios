import Foundation

public struct GospelResponse: Codable {
    public var result: [Gospel]
    public var status: String
    public var version: String
}

