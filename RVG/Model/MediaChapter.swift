import Foundation
import GRDB

public struct MediaChapter: Codable, Playable {
    public var hash_id: String
    
    public var inserted_at: String
    
    public var large_thumbnail_path: String?
    
    public var media_category: String
    
    public var med_thumbnail_path: String?
    
    public var presenter_name: String?
    
    public var playlist_uuid: String
    
    public var small_thumbnail_path: String?
    
    public var source_material: String?
    
    public var track_number: Int?
    
    public var updated_at: String?
    
    
    public var createdAt: Double?
    
    public var categoryUuid: String?
    //    public var createdAt: Double?
    public var contentProviderLink: String?
    public var duration: TimeInterval
    public var ipfsLink: String?
    public var languageId: String
    public var localizedname: String
    //    public var localizedName: String?
    public var medium: String
    public var multilanguage: Bool
    public var ordinal: Int?
    public var path: String?
    public var presentedAt: TimeInterval?
    public var publishedAt: TimeInterval?
    public var tags: String
    public var uuid: String

}

// Define columns so that we can build GRDB requests
extension MediaChapter {
    enum Columns {
//        static let userId = Column("userId")
        static let duration = Column("duration")
        static let uuid = Column("uuid")
        static let localizedName = Column("localizedName")
        static let path = Column("path")
        static let presenter_name = Column("presenter_name")
        static let source_material = Column("source_material")
        static let categoryUuid = Column("categoryUuid")
        static let track_number = Column("track_number")
        static let createdAt = Column("createdAt")
        static let updated_at = Column("updated_at")
        static let large_thumbnail_path = Column("large_thumbnail_path")
        static let small_thumbnail_path = Column("small_thumbnail_path")
        static let multilanguage = Column("multilanguage")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension MediaChapter: FetchableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension MediaChapter: MutablePersistableRecord {
    public static let databaseTableName = "mediachapter"
    public mutating func didInsert(with rowID: String, for column: String?) {
        uuid = rowID
    }
}

