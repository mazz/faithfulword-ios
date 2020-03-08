import Foundation
import GRDB

public struct MediaItem: Codable, Playable {    
//    public var createdAt: Double?
//
//    public var categoryUuid: String?
//    public var createdAt: Double?
    public var content_provider_link: String?
    public var duration: TimeInterval
    public var hash_id: String
    public var inserted_at: String
    public var ipfs_link: String?
    public var language_id: String?
    public var large_thumbnail_path: String?
    public var localizedname: String
//    public var localizedName: String?
    public var med_thumbnail_path: String?
    public var media_category: String
    public var medium: String
    public var multilanguage: Bool
    public var ordinal: Int?
    public var path: String?
    public var playlist_uuid: String
    public var presented_at: String?
    public var presenter_name: String?
    public var published_at: String?
    public var small_thumbnail_path: String?
    public var source_material: String?
    public var tags: [String]?
    public var track_number: Int?
    public var updated_at: String?
    public var uuid: String
    
    //
    // a MediaItem is many-to-one to Playlist
    //
    static let mediaitemForeignKey = ForeignKey([Columns.playlist_uuid])

//    enum CodingKeys: String, CodingKey {
////        case createdAt
////        case categoryUuid
//        case contentProviderLink
//        case hashId
//        case insertedAt
//        case ipfsLink
//        case languageId
//        case largeThumbnailPath
//        case localizedname
//        case mediaCategory
//        case medium
//        case medThumbnailPath
//        case ordinal
//        case path
//        case playlistUuid
//        case presentedAt
//        case publishedAt
//        case smallThumbnailPath
//        case sourceMaterial
//        case tags
//        case trackNumber
//        case updatedAt
//        case uuid
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//
////        self.createdAt = try values.decodeIfPresent(Double.self, forKey: .createdAt)
////        try container.encodeIfPresent(createdAt, forKey: .createdAt)
////        try container.encodeIfPresent(categoryUuid, forKey: .categoryUuid)
//
//        try container.encode(contentProviderLink, forKey: .contentProviderLink)
//        try container.encode(hashId, forKey: .hashId)
//        try container.encode(insertedAt, forKey: .insertedAt)
//        try container.encode(ipfsLink, forKey: .ipfsLink)
//        try container.encode(languageId, forKey: .languageId)
//        try container.encode(largeThumbnailPath, forKey: .largeThumbnailPath)
//        try container.encode(localizedname, forKey: .localizedname)
////        try container.encodeIfPresent(localizedName, forKey: .localizedName)
//        try container.encode(mediaCategory, forKey: .mediaCategory)
//        try container.encode(medium, forKey: .medium)
//        try container.encode(medThumbnailPath, forKey: .medThumbnailPath)
//        try container.encode(ordinal, forKey: .ordinal)
//        try container.encode(path, forKey: .path)
//        try container.encode(playlistUuid, forKey: .playlistUuid)
//        try container.encode(presentedAt, forKey: .presentedAt)
//        try container.encode(publishedAt, forKey: .publishedAt)
//        try container.encode(smallThumbnailPath, forKey: .smallThumbnailPath)
//        try container.encode(sourceMaterial, forKey: .sourceMaterial)
//        try container.encode(tags, forKey: .tags)
//        try container.encode(trackNumber, forKey: .trackNumber)
//        try container.encode(updatedAt, forKey: .updatedAt)
//        try container.encode(uuid, forKey: .uuid)
//    }
//
//    public init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//
////        self.createdAt = try values.decodeIfPresent(Double.self, forKey: .createdAt)
////        self.categoryUuid = try values.decodeIfPresent(String.self, forKey: .categoryUuid)
//
//        if let contentProviderLink: String = try values.decodeIfPresent(String.self, forKey: .contentProviderLink) {
//            self.contentProviderLink = contentProviderLink
//        }
//        self.hashId = try values.decode(String.self, forKey: .hashId)
//        self.insertedAt = try values.decode(TimeInterval.self, forKey: .insertedAt)
//
//        if let ipfsLink: String = try values.decodeIfPresent(String.self, forKey: .ipfsLink) {
//            self.ipfsLink = ipfsLink
//        }
//
//        self.languageId = try values.decode(String.self, forKey: .languageId)
//        self.localizedname = try values.decode(String.self, forKey: .localizedname)
////        self.localizedName = try! values.decodeIfPresent(String.self, forKey: .localizedName)
//
//
//        if let largeThumbnailPath: String = try values.decodeIfPresent(String.self, forKey: .largeThumbnailPath) {
//            self.largeThumbnailPath = largeThumbnailPath
//        }
//
////        self.largeThumbnailPath = try? values.decode(String.self, forKey: .largeThumbnailPath)
//        self.mediaCategory = try values.decode(String.self, forKey: .mediaCategory)
//        self.medium = try values.decode(String.self, forKey: .medium)
//
//
//        if let medThumbnailPath: String = try values.decodeIfPresent(String.self, forKey: .medThumbnailPath) {
//            self.medThumbnailPath = medThumbnailPath
//        }
//
////        self.medThumbnailPath = try? values.decode(String.self, forKey: .medThumbnailPath)
//
//        if let ordinal: Int = try values.decodeIfPresent(Int.self, forKey: .ordinal) {
//            self.ordinal = ordinal
//        }
//
////        self.ordinal = try? values.decode(Int.self, forKey: .ordinal)
//        self.path = try values.decode(String.self, forKey: .path)
//        self.playlistUuid = try values.decode(String.self, forKey: .playlistUuid)
//
//        if let presentedAt: TimeInterval = try values.decodeIfPresent(TimeInterval.self, forKey: .presentedAt) {
//            self.presentedAt = presentedAt
//        }
//
////        self.presentedAt = try? values.decode(TimeInterval.self, forKey: .presentedAt)
//
//        if let publishedAt: TimeInterval = try values.decodeIfPresent(TimeInterval.self, forKey: .publishedAt) {
//            self.publishedAt = publishedAt
//        }
//
////        self.publishedAt = try? values.decode(TimeInterval.self, forKey: .publishedAt)
//
//
//        if let smallThumbnailPath: String = try values.decodeIfPresent(String.self, forKey: .smallThumbnailPath) {
//            self.smallThumbnailPath = smallThumbnailPath
//        }
////        self.smallThumbnailPath = try? values.decode(String.self, forKey: .smallThumbnailPath)
//        self.sourceMaterial = try values.decode(String.self, forKey: .sourceMaterial)
//
//        let tagsArray: [String] = try values.decode([String].self, forKey: .tags)
//
//        self.tags = tagsArray.joined(separator:",")
//        self.trackNumber = try values.decode(Int.self, forKey: .trackNumber)
//        self.updatedAt = try values.decode(TimeInterval.self, forKey: .updatedAt)
//        self.uuid = try values.decode(String.self, forKey: .uuid)
//    }
    
}

// Define columns so that we can build GRDB requests
extension MediaItem {
    enum Columns {
        static let content_provider_link = Column("content_provider_link")
        static let duration = Column("duration")
        static let hash_id = Column("hash_id")
        static let inserted_at = Column("inserted_at")
        static let ipfs_link = Column("ipfs_link")
        static let language_id = Column("language_id")
        static let localizedname = Column("localizedname")
        static let large_thumbnail_path = Column("large_thumbnail_path")
        static let media_category = Column("media_category")
        static let medium = Column("medium")
        static let med_thumbnail_path = Column("med_thumbnail_path")
        static let multilanguage = Column("multilanguage")
        static let ordinal = Column("ordinal")
        static let path = Column("path")
        static let playlist_uuid = Column("playlist_uuid")
        static let presented_at = Column("presented_at")
        static let presenter_name = Column("presenter_name")
        static let published_at = Column("published_at")
        static let small_thumbnail_path = Column("small_thumbnail_path")
        static let source_material = Column("source_material")
        static let tags = Column("tags")
        static let track_number = Column("track_number")
        static let updated_at = Column("updated_at")
        static let uuid = Column("uuid")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension MediaItem: FetchableRecord, PersistableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
//extension MediaItem: MutablePersistableRecord {
//    public static let databaseTableName = "mediaitem"
//    public mutating func didInsert(with rowID: String, for column: String?) {
//        uuid = rowID
//    }
//}

