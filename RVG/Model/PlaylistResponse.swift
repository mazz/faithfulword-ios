import Foundation

public struct PlaylistResponse: Codable {
    public var pageSize: Int
    public var pageNumber: Int
    public var result: [Playlist]
    public var status: String
    public var totalPages: Int
    public var totalEntries: Int
    public var version: String
}
