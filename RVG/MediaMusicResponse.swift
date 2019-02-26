import Foundation

public struct MediaMusicResponse: Codable {
    public var pageSize: Int
    public var pageNumber: Int
    public var result: [MediaMusic]
    public var status: String
    public var totalPages: Int
    public var totalEntries: Int
    public var version: String
}
