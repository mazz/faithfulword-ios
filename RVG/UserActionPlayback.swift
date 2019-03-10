import Foundation
import GRDB

public struct UserActionPlayback: Codable {
    var userActionPlaybackId: Int64?
    var uuid: String
    var playableUuid: String
    var playablePath: String?
    var createdAt: Double?
    var updatedAt: Double?
    var playbackPosition: Double
    var downloaded: Bool
}

// Define colums so that we can build GRDB requests
extension UserActionPlayback {
    enum Columns {
        static let userActionPlaybackId = Column("userActionPlaybackId")
        static let uuid = Column("uuid")
        static let playableUuid = Column("playableUuid")
        static let playablePath = Column("playablePath")
        static let createdAt = Column("createdAt")
        static let updatedAt = Column("updatedAt")
        static let playbackPosition = Column("playbackPosition")
        static let downloaded = Column("downloaded")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension UserActionPlayback: FetchableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension UserActionPlayback: MutablePersistableRecord {
    public static let databaseTableName = "useractionplayback"
    public mutating func didInsert(with rowID: Int64, for column: String?) {
        userActionPlaybackId = rowID
    }
}
