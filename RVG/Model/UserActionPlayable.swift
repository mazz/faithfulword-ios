import Foundation
import GRDB

public struct UserActionPlayable: Codable, Playable {
    public var language_id: String?
    
    public var ordinal: Int?
    
    public var tags: [String]?
    
//    public var userActionPlayableId: Int64?
    public var downloaded: Bool
    public var duration: TimeInterval
//    public var categoryUuid: String?
    public var hash_id: String
    public var playable_uuid: String
    public var playable_path: String?
    public var playback_position: Double
    public var updated_at: String?
    public var uuid: String
    // Playable
    public var localizedname: String
//    public var path: String?
//    public var presenterName: String?
//    public var sourceMaterial: String?
//    public var trackNumber: Int?
//    public var largeThumbnailPath: String?
//    public var smallThumbnailPath: String?
//    public var createdAt: Double?
//
//    public var categoryUuid: String?
    //    public var createdAt: Double?
//    public var contentProviderLink: String?
//    public var hashId: String
    public var inserted_at: String
//    public var ipfsLink: String?
//    public var language_id: String
    public var large_thumbnail_path: String?
//    public var localizedname: String
    //    public var localizedName: String?
//    public var medThumbnailPath: String?
    public var media_category: String
    public var multilanguage: Bool
//    public var medium: String
//    public var ordinal: Int
    public var path: String?
    public var playlist_uuid: String
    public var presented_at: String?
    public var presenter_name: String?
    public var published_at: String?
    public var small_thumbnail_path: String?
    public var med_thumbnail_path: String?
    public var source_material: String?
//    public var tags: [String]
    public var track_number: Int?
//    public var uuid: String
}

// Define colums so that we can build GRDB requests
extension UserActionPlayable {
    enum Columns {
//        static let userActionPlayableId = Column("userActionPlayableId")
        static let downloaded = Column("downloaded")
        static let duration = Column("duration")
        static let playable_path = Column("playable_path")
        static let inserted_at = Column("inserted_at")
        static let updated_at = Column("updated_at")
        static let playback_position = Column("playback_position")
        static let uuid = Column("uuid")

        // Playable
        static let hash_id = Column("hash_id")
        static let large_thumbnail_path = Column("large_thumbnail_path")
        static let localizedname = Column("localizedname")
        static let language_id = Column("language_id")
        static let media_category = Column("media_category")
        static let med_thumbnail_path = Column("med_thumbnail_path")
        static let multilanguage = Column("multilanguage")
        static let ordinal = Column("ordinal")
        static let path = Column("path")
        static let playable_uuid = Column("playable_uuid")
        static let playlist_uuid = Column("playlist_uuid")
        static let presented_at = Column("presented_at")
        static let published_at = Column("published_at")
        static let presenter_name = Column("presenter_name")
        static let source_material = Column("source_material")
        static let small_thumbnail_path = Column("small_thumbnail_path")
        static let tags = Column("tags")
        static let track_number = Column("track_number")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension UserActionPlayable: FetchableRecord, PersistableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
//extension UserActionPlayable: MutablePersistableRecord {
//    public static let databaseTableName = "useractionplayable"
//    public mutating func didInsert(with rowID: Int64, for column: String?) {
//        userActionPlayableId = rowID
//    }
//}
