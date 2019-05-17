import Foundation
import GRDB

public struct Channel: Codable {
//    var userId: Int64?
    var uuid: String
    public var orgUuid: String
    public var bannerPath: String?
    public var basename: String
    public var ordinal: Int?
    public var insertedAt: TimeInterval
    public var updatedAt: TimeInterval
    public var largeThumbnailPath: String?
    public var medThumbnailPath: String?
    public var smallThumbnailPath: String?

    enum CodingKeys: String, CodingKey {
//        case userId
        case uuid
        case orgUuid
        case bannerPath
        case basename
        case ordinal
        case insertedAt
        case updatedAt
        case largeThumbnailPath
        case medThumbnailPath
        case smallThumbnailPath
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(userId, forKey: .userId)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(orgUuid, forKey: .orgUuid)
        try container.encode(bannerPath, forKey: .bannerPath)
        try container.encode(basename, forKey: .basename)
        try container.encode(ordinal, forKey: .ordinal)
        try container.encode(insertedAt, forKey: .insertedAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(largeThumbnailPath, forKey: .largeThumbnailPath)
        try container.encode(medThumbnailPath, forKey: .medThumbnailPath)
        try container.encode(smallThumbnailPath, forKey: .smallThumbnailPath)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
//        self.userId = try? values.decode(Int64.self, forKey: .userId)
        // take categoryUuid, if not exist then take uuid (at least one of them must present)
        self.uuid = try values.decode(String.self, forKey: .uuid)
        self.orgUuid = try values.decode(String.self, forKey: .orgUuid)
        self.bannerPath = try? values.decode(String.self, forKey: .bannerPath)
        self.basename = try values.decode(String.self, forKey: .basename)
        self.ordinal = try? values.decode(Int.self, forKey: .ordinal)
        self.insertedAt = try values.decode(TimeInterval.self, forKey: .insertedAt)
        self.updatedAt = try values.decode(TimeInterval.self, forKey: .updatedAt)
        self.largeThumbnailPath = try? values.decode(String.self, forKey: .largeThumbnailPath)
        self.medThumbnailPath = try? values.decode(String.self, forKey: .medThumbnailPath)
        self.smallThumbnailPath = try? values.decode(String.self, forKey: .smallThumbnailPath)
    }

}

// Define columns so that we can build GRDB requests
extension Channel {
    enum Columns {
//        static let userId = Column("userId")
        static let uuid = Column("uuid")
        static let orgUuid = Column("orgUuid")
        static let bannerPath = Column("bannerPath")
        static let basename = Column("basename")
        static let ordinal = Column("ordinal")
        static let insertedAt = Column("insertedAt")
        static let updatedAt = Column("updatedAt")
        static let largeThumbnailPath = Column("largeThumbnailPath")
        static let medThumbnailPath = Column("medThumbnailPath")
        static let smallThumbnailPath = Column("smallThumbnailPath")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension Channel: FetchableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension Channel: MutablePersistableRecord {
    public static let databaseTableName = "channel"
    public mutating func didInsert(with rowID: String, for column: String?) {
        uuid = rowID
    }
}
