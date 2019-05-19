import Foundation
import GRDB

public struct MediaItem: Codable {
    public var contentProviderLink: String?
    public var insertedAt: TimeInterval
    public var ipfsLink: String?
    public var languageId: String
    public var localizedname: String
    public var largeThumbnailPath: String?
    public var mediaCategory: String
    public var medium: String
    public var medThumbnailPath: String?
    public var ordinal: Int?
    public var path: String
    public var playlistUuid: String
    public var presentedAt: TimeInterval
    public var publishedAt: TimeInterval?
    public var smallThumbnailPath: String?
    public var sourceMaterial: String
    public var tags: String
    public var trackNumber: Int
    public var updatedAt: TimeInterval
    var uuid: String
    
    enum CodingKeys: String, CodingKey {
        case contentProviderLink
        case insertedAt
        case ipfsLink
        case languageId
        case largeThumbnailPath
        case localizedname
        case mediaCategory
        case medium
        case medThumbnailPath
        case ordinal
        case path
        case playlistUuid
        case presentedAt
        case publishedAt
        case smallThumbnailPath
        case sourceMaterial
        case tags
        case trackNumber
        case updatedAt
        case uuid
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(contentProviderLink, forKey: .contentProviderLink)
        try container.encode(insertedAt, forKey: .insertedAt)
        try container.encode(ipfsLink, forKey: .ipfsLink)
        try container.encode(languageId, forKey: .languageId)
        try container.encode(largeThumbnailPath, forKey: .largeThumbnailPath)
        try container.encode(localizedname, forKey: .localizedname)
        try container.encode(mediaCategory, forKey: .mediaCategory)
        try container.encode(medium, forKey: .medium)
        try container.encode(medThumbnailPath, forKey: .medThumbnailPath)
        try container.encode(ordinal, forKey: .ordinal)
        try container.encode(path, forKey: .path)
        try container.encode(playlistUuid, forKey: .playlistUuid)
        try container.encode(presentedAt, forKey: .presentedAt)
        try container.encode(publishedAt, forKey: .publishedAt)
        try container.encode(smallThumbnailPath, forKey: .smallThumbnailPath)
        try container.encode(sourceMaterial, forKey: .sourceMaterial)
        try container.encode(tags, forKey: .tags)
        try container.encode(trackNumber, forKey: .trackNumber)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(uuid, forKey: .uuid)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.contentProviderLink = try? values.decode(String.self, forKey: .contentProviderLink)
        self.insertedAt = try values.decode(TimeInterval.self, forKey: .insertedAt)
        self.ipfsLink = try? values.decode(String.self, forKey: .ipfsLink)
        self.languageId = try values.decode(String.self, forKey: .languageId)
        self.localizedname = try values.decode(String.self, forKey: .localizedname)
        self.largeThumbnailPath = try? values.decode(String.self, forKey: .largeThumbnailPath)
        self.mediaCategory = try values.decode(String.self, forKey: .mediaCategory)
        self.medium = try values.decode(String.self, forKey: .medium)
        self.medThumbnailPath = try? values.decode(String.self, forKey: .medThumbnailPath)
        self.ordinal = try? values.decode(Int.self, forKey: .ordinal)
        self.path = try values.decode(String.self, forKey: .path)
        self.playlistUuid = try values.decode(String.self, forKey: .playlistUuid)
        self.presentedAt = try values.decode(TimeInterval.self, forKey: .presentedAt)
        self.publishedAt = try? values.decode(TimeInterval.self, forKey: .publishedAt)
        self.smallThumbnailPath = try? values.decode(String.self, forKey: .smallThumbnailPath)
        self.sourceMaterial = try values.decode(String.self, forKey: .sourceMaterial)
        
        let tagsArray: [String] = try values.decode([String].self, forKey: .tags)
        
        self.tags = tagsArray.joined(separator:",")
        self.trackNumber = try values.decode(Int.self, forKey: .trackNumber)
        self.updatedAt = try values.decode(TimeInterval.self, forKey: .updatedAt)
        self.uuid = try values.decode(String.self, forKey: .uuid)
    }
    
}

// Define columns so that we can build GRDB requests
extension MediaItem {
    enum Columns {
        static let contentProviderLink = Column("contentProviderLink")
        static let insertedAt = Column("insertedAt")
        static let ipfsLink = Column("ipfsLink")
        static let languageId = Column("languageId")
        static let localizedname = Column("localizedname")
        static let largeThumbnailPath = Column("largeThumbnailPath")
        static let mediaCategory = Column("mediaCategory")
        static let medium = Column("medium")
        static let medThumbnailPath = Column("medThumbnailPath")
        static let ordinal = Column("ordinal")
        static let path = Column("path")
        static let playlistUuid = Column("playlistUuid")
        static let presentedAt = Column("presentedAt")
        static let publishedAt = Column("publishedAt")
        static let smallThumbnailPath = Column("smallThumbnailPath")
        static let sourceMaterial = Column("sourceMaterial")
        static let tags = Column("tags")
        static let trackNumber = Column("trackNumber")
        static let updatedAt = Column("updatedAt")
        static let uuid = Column("uuid")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension MediaItem: FetchableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension MediaItem: MutablePersistableRecord {
    public static let databaseTableName = "mediaitem"
    public mutating func didInsert(with rowID: String, for column: String?) {
        uuid = rowID
    }
}

