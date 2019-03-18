import Foundation
import GRDB

public struct UserActionPlayable: Codable, Playable {
    public var userActionPlayableId: Int64?
    public var uuid: String
    public var categoryUuid: String?
    public var playableUuid: String
    public var playablePath: String?
    public var createdAt: Double?
    public var updatedAt: Double?
    public var playbackPosition: Double
    public var downloaded: Bool
    // Playable
    public var localizedName: String?
    public var path: String?
    public var presenterName: String?
    public var sourceMaterial: String?
    public var trackNumber: Int64?
    public var largeThumbnailPath: String?
    public var smallThumbnailPath: String?    
}

// Define colums so that we can build GRDB requests
extension UserActionPlayable {
    enum Columns {
        static let userActionPlayableId = Column("userActionPlayableId")
        static let uuid = Column("uuid")
        static let playableUuid = Column("playableUuid")
        static let playablePath = Column("playablePath")
        static let createdAt = Column("createdAt")
        static let updatedAt = Column("updatedAt")
        static let playbackPosition = Column("playbackPosition")
        static let downloaded = Column("downloaded")

        // Playable
        static let categoryUuid = Column("categoryUuid")
        static let localizedName = Column("localizedName")
        static let path = Column("path")
        static let presenterName = Column("presenterName")
        static let sourceMaterial = Column("sourceMaterial")
        static let trackNumber = Column("trackNumber")
        static let largeThumbnailPath = Column("largeThumbnailPath")
        static let smallThumbnailPath = Column("smallThumbnailPath")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension UserActionPlayable: FetchableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension UserActionPlayable: MutablePersistableRecord {
    public static let databaseTableName = "useractionplayable"
    public mutating func didInsert(with rowID: Int64, for column: String?) {
        userActionPlayableId = rowID
    }
}
