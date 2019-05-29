import Foundation
import GRDB

public struct Playlist: Codable {
    var uuid: String
    public var channelUuid: String
    public var bannerPath: String?
    public var localizedname: String
    public var languageId: String
    public var mediaCategory: String
    public var ordinal: Int?
    public var insertedAt: TimeInterval
    public var updatedAt: TimeInterval
    public var largeThumbnailPath: String?
    public var medThumbnailPath: String?
    public var smallThumbnailPath: String?
    
//    enum CodingKeys: String, CodingKey {
//        case uuid
//        case channelUuid
//        case bannerPath
//        case localizedname
//        case languageId
//        case mediaCategory
//        case ordinal
//        case insertedAt
//        case updatedAt
//        case largeThumbnailPath
//        case medThumbnailPath
//        case smallThumbnailPath
//    }
    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(uuid, forKey: .uuid)
//        try container.encode(channelUuid, forKey: .channelUuid)
//        try container.encode(bannerPath, forKey: .bannerPath)
//        try container.encode(localizedname, forKey: .localizedname)
//        try container.encode(languageId, forKey: .languageId)
//        try container.encode(mediaCategory, forKey: .mediaCategory)
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
//        self.uuid = try values.decode(String.self, forKey: .uuid)
//        self.channelUuid = try values.decode(String.self, forKey: .channelUuid)
//        self.bannerPath = try? values.decode(String.self, forKey: .bannerPath)
//        self.localizedname = try values.decode(String.self, forKey: .localizedname)
//        self.languageId = try values.decode(String.self, forKey: .languageId)
//        self.mediaCategory = try values.decode(String.self, forKey: .mediaCategory)
//        self.ordinal = try? values.decode(Int.self, forKey: .ordinal)
//        self.insertedAt = try values.decode(TimeInterval.self, forKey: .insertedAt)
//        self.updatedAt = try values.decode(TimeInterval.self, forKey: .updatedAt)
//        self.largeThumbnailPath = try? values.decode(String.self, forKey: .largeThumbnailPath)
//        self.medThumbnailPath = try? values.decode(String.self, forKey: .medThumbnailPath)
//        self.smallThumbnailPath = try? values.decode(String.self, forKey: .smallThumbnailPath)
//    }
    
}

// Define columns so that we can build GRDB requests
extension Playlist {
    enum Columns {
        static let uuid = Column("uuid")
        static let channelUuid = Column("channelUuid")
        static let bannerPath = Column("bannerPath")
        static let localizedname = Column("localizedname")
        static let languageId = Column("languageId")
        static let mediaCategory = Column("mediaCategory")
        static let ordinal = Column("ordinal")
        static let insertedAt = Column("insertedAt")
        static let updatedAt = Column("updatedAt")
        static let largeThumbnailPath = Column("largeThumbnailPath")
        static let medThumbnailPath = Column("medThumbnailPath")
        static let smallThumbnailPath = Column("smallThumbnailPath")
    }
}

extension Playlist: FetchableRecord, PersistableRecord { }

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
//extension Playlist: FetchableRecord { }
//
//// Adopt MutablePersistable so that we can create/update/delete players in the database.
//// Implementation is partially derived from Codable.
//extension Playlist: MutablePersistableRecord {
//    public static let databaseTableName = "playlist"
//    public mutating func didInsert(with rowID: String, for column: String?) {
//        uuid = rowID
//    }
//}

