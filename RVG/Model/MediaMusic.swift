import Foundation
import GRDB

public struct MediaMusic: Codable, Playable {

    //    var bookId: Int64?
    //    var userId: Int64?
//    public var uuid: String
//    public var localizedName: String?
//    public var path: String?
//    public var presenterName: String?
//    public var sourceMaterial: String?
//    public var categoryUuid: String?
//    public var trackNumber: Int?
//    public var createdAt: Double?
//    public var updatedAt: Double?
//    public var largeThumbnailPath: String?
//    public var smallThumbnailPath: String?

    public var createdAt: Double?
    
    public var categoryUuid: String?
    //    public var createdAt: Double?
    public var contentProviderLink: String?
    public var hashId: String
    public var insertedAt: TimeInterval
    public var ipfsLink: String?
    public var languageId: String
    public var largeThumbnailPath: String?
    public var localizedname: String
    //    public var localizedName: String?
    public var medThumbnailPath: String?
    public var mediaCategory: String
    public var medium: String
    public var ordinal: Int?
    public var path: String?
    public var playlistUuid: String
    public var presentedAt: TimeInterval?
    public var presenterName: String?
    public var publishedAt: TimeInterval?
    public var smallThumbnailPath: String?
    public var sourceMaterial: String?
    public var tags: String
    public var trackNumber: Int?
    public var updatedAt: TimeInterval?
    public var uuid: String

}

// Define columns so that we can build GRDB requests
extension MediaMusic {
    enum Columns {
        //        static let userId = Column("userId")
        static let uuid = Column("uuid")
        static let localizedName = Column("localizedName")
        static let path = Column("path")
        static let presenterName = Column("presenterName")
        static let sourceMaterial = Column("sourceMaterial")
        static let categoryUuid = Column("categoryUuid")
        static let trackNumber = Column("trackNumber")
        static let createdAt = Column("createdAt")
        static let updatedAt = Column("updatedAt")
        static let largeThumbnailPath = Column("largeThumbnailPath")
        static let smallThumbnailPath = Column("smallThumbnailPath")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension MediaMusic: FetchableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension MediaMusic: MutablePersistableRecord {
    public static let databaseTableName = "mediamusic"
    public mutating func didInsert(with rowID: String, for column: String?) {
        uuid = rowID
    }
}

