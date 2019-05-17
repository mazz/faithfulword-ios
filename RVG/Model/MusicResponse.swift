
import Foundation

public struct MusicResponse: Codable {
    public var pageSize: Int
    public var pageNumber: Int
    public var result: [Music]
    public var status: String
    public var totalPages: Int
    public var totalEntries: Int
    public var version: String
}

