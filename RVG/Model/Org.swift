import Foundation
import GRDB

public struct Org: Codable {
//    var userId: Int64?
    public var uuid: String
    public var orgId: Int
    public var bannerPath: String?
    public var basename: String
    public var shortname: String
    public var insertedAt: TimeInterval
    public var updatedAt: TimeInterval
    public var largeThumbnailPath: String?
    public var medThumbnailPath: String?
    public var smallThumbnailPath: String?

    //
    // a Org is one-to-many to Channel
    //
    static let channels = hasMany(Channel.self, using: Channel.channelForeignKey)
    
//    enum CodingKeys: String, CodingKey {
////        case userId
//        case uuid
//        case bannerPath
//        case basename
//        case shortname
//        case insertedAt
//        case updatedAt
//        case largeThumbnailPath
//        case medThumbnailPath
//        case smallThumbnailPath
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
////        try container.encode(userId, forKey: .userId)
//        try container.encode(uuid, forKey: .uuid)
//        try container.encode(bannerPath, forKey: .bannerPath)
//        try container.encode(basename, forKey: .basename)
//        try container.encode(shortname, forKey: .shortname)
//        try container.encode(insertedAt, forKey: .insertedAt)
//        try container.encode(updatedAt, forKey: .updatedAt)
//        try container.encode(largeThumbnailPath, forKey: .largeThumbnailPath)
//        try container.encode(medThumbnailPath, forKey: .medThumbnailPath)
//        try container.encode(smallThumbnailPath, forKey: .smallThumbnailPath)
//    }
//
//    public init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//
////        self.userId = try? values.decode(Int64.self, forKey: .userId)
//        // take categoryUuid, if not exist then take uuid (at least one of them must present)
//        self.uuid = try values.decode(String.self, forKey: .uuid)
//        self.bannerPath = try? values.decode(String.self, forKey: .bannerPath)
//        self.basename = try values.decode(String.self, forKey: .basename)
//        self.shortname = try values.decode(String.self, forKey: .shortname)
//        self.insertedAt = try values.decode(TimeInterval.self, forKey: .insertedAt)
//        self.updatedAt = try values.decode(TimeInterval.self, forKey: .updatedAt)
//        self.largeThumbnailPath = try? values.decode(String.self, forKey: .largeThumbnailPath)
//        self.medThumbnailPath = try? values.decode(String.self, forKey: .medThumbnailPath)
//        self.smallThumbnailPath = try? values.decode(String.self, forKey: .smallThumbnailPath)
//    }
//
}

// Define columns so that we can build GRDB requests
extension Org {
    enum Columns {
//        static let userId = Column("userId")
        static let uuid = Column("uuid")
        static let orgId = Column("orgId")
        static let bannerPath = Column("bannerPath")
        static let basename = Column("basename")
        static let shortname = Column("shortname")
        static let insertedAt = Column("insertedAt")
        static let updatedAt = Column("updatedAt")
        static let largeThumbnailPath = Column("largeThumbnailPath")
        static let medThumbnailPath = Column("medThumbnailPath")
        static let smallThumbnailPath = Column("smallThumbnailPath")
    }
}

// Adopt RowConvertible so that we can fetch Orgs from the database.
// Implementation is automatically derived from Codable.
extension Org: FetchableRecord, PersistableRecord { }

