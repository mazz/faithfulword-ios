import Foundation

public struct PlaylistResponse: Codable {
    public var page_size: Int
    public var page_number: Int
    public var result: [Playlist]
    public var status: String
    public var total_pages: Int
    public var total_entries: Int
    public var version: String
}
