import Foundation
import GRDB

public struct Channel: Codable {
//    var userId: Int64?
    var uuid: String
    public var org_uuid: String
    public var banner_path: String?
    public var basename: String
    public var ordinal: Int?
    public var inserted_at: String
    public var updated_at: String
    public var large_thumbnail_path: String?
    public var med_thumbnail_path: String?
    public var small_thumbnail_path: String?

    //
    // a Channel is many-to-one to Org
    //
    static let channelForeignKey = ForeignKey([Columns.org_uuid])
    
    //
    // a Channel is one-to-many to Playlist
    //
    static let playlists = hasMany(Playlist.self, using: Playlist.playlistForeignKey)

//    enum CodingKeys: String, CodingKey {
////        case userId
//        case uuid
//        case orgUuid
//        case bannerPath
//        case basename
//        case ordinal
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
//        try container.encode(orgUuid, forKey: .orgUuid)
//        try container.encode(bannerPath, forKey: .bannerPath)
//        try container.encode(basename, forKey: .basename)
//        try container.encode(ordinal, forKey: .ordinal)
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
//        self.orgUuid = try values.decode(String.self, forKey: .orgUuid)
//        self.bannerPath = try? values.decode(String.self, forKey: .bannerPath)
//        self.basename = try values.decode(String.self, forKey: .basename)
//        self.ordinal = try? values.decode(Int.self, forKey: .ordinal)
//        self.insertedAt = try values.decode(TimeInterval.self, forKey: .insertedAt)
//        self.updatedAt = try values.decode(TimeInterval.self, forKey: .updatedAt)
//        self.largeThumbnailPath = try? values.decode(String.self, forKey: .largeThumbnailPath)
//        self.medThumbnailPath = try? values.decode(String.self, forKey: .medThumbnailPath)
//        self.smallThumbnailPath = try? values.decode(String.self, forKey: .smallThumbnailPath)
//    }

}

// Define columns so that we can build GRDB requests
extension Channel {
    enum Columns {
//        static let userId = Column("userId")
        static let uuid = Column("uuid")
        static let org_uuid = Column("org_uuid")
        static let banner_path = Column("banner_path")
        static let basename = Column("basename")
        static let ordinal = Column("ordinal")
        static let inserted_at = Column("inserted_at")
        static let update_at = Column("update_at")
        static let large_thumbnail_path = Column("large_thumbnail_path")
        static let med_thumbnail_path = Column("med_thumbnail_path")
        static let small_thumbnail_path = Column("small_thumbnail_path")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension Channel: FetchableRecord, PersistableRecord { }
