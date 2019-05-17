import Foundation

public struct OrgResponse: Codable {
    public var pageSize: Int
    public var pageNumber: Int
    public var result: [Org]
    public var status: String
    public var totalPages: Int
    public var totalEntries: Int
    public var version: String
}
