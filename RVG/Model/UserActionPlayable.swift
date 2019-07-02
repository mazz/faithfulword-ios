import Foundation
import GRDB

public struct UserActionPlayable: Codable, Playable {
//    public var userActionPlayableId: Int64?
    public var downloaded: Bool
    public var duration: TimeInterval
//    public var categoryUuid: String?
    public var hashId: String
    public var playableUuid: String
    public var playablePath: String?
    public var playbackPosition: Double
    public var updatedAt: Double?
    public var uuid: String
    // Playable
//    public var localizedName: String?
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
    public var insertedAt: TimeInterval
//    public var ipfsLink: String?
//    public var languageId: String
    public var largeThumbnailPath: String?
    public var localizedname: String
    //    public var localizedName: String?
//    public var medThumbnailPath: String?
    public var mediaCategory: String
//    public var medium: String
//    public var ordinal: Int?
    public var path: String?
    public var playlistUuid: String
//    public var presentedAt: TimeInterval?
    public var presenterName: String?
//    public var publishedAt: TimeInterval?
    public var smallThumbnailPath: String?
    public var medThumbnailPath: String?
    public var sourceMaterial: String?
//    public var tags: String
    public var trackNumber: Int?
//    public var updatedAt: TimeInterval?
//    public var uuid: String
}

// Define colums so that we can build GRDB requests
extension UserActionPlayable {
    enum Columns {
//        static let userActionPlayableId = Column("userActionPlayableId")
        static let downloaded = Column("downloaded")
        static let duration = Column("duration")
        static let playablePath = Column("playablePath")
        static let insertedAt = Column("insertedAt")
        static let updatedAt = Column("updatedAt")
        static let playbackPosition = Column("playbackPosition")
        static let uuid = Column("uuid")

        // Playable
        static let hashId = Column("hashId")
        static let largeThumbnailPath = Column("smallThumbnailPath")
        static let localizedname = Column("localizedname")
        static let mediaCategory = Column("mediaCategory")
        static let medThumbnailPath = Column("medThumbnailPath")
        static let path = Column("path")
        static let playableUuid = Column("playableUuid")
        static let playlistUuid = Column("playlistUuid")
        static let presenterName = Column("presenterName")
        static let sourceMaterial = Column("sourceMaterial")
        static let smallThumbnailPath = Column("smallThumbnailPath")
        static let trackNumber = Column("trackNumber")
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
