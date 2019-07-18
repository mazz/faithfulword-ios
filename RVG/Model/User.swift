import Foundation
import GRDB

public struct User: Codable {
    var userId: Int64?
    public var uuid: String?
    public var name: String
    public var email: String?
    public var session: String
    public var pushNotifications: Bool
    public var language: String

    //
    // a User is one-to-many to FileDownloadItem
    //
    static let downloads = hasMany(FileDownloadItem.self, using: FileDownloadItem.downloaditemForeignKey)

//    enum CodingKeys: String, CodingKey {
//        case uuid
//        case name
//        case session
//        case pushNotifications
//        case language
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(uuid, forKey: .uuid)
//        try container.encode(session, forKey: .session)
//        try container.encode(pushNotifications, forKey: .pushNotifications)
//        try container.encode(language, forKey: .language)
//    }
//    
//    public init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        
//        self.uuid = try values.decode(String.self, forKey: .uuid)
//        self.name = try values.decode(String.self, forKey: .name)
//        self.session = try values.decode(String.self, forKey: .session)
//        self.pushNotifications = try values.decode(Bool.self, forKey: .pushNotifications)
//        self.language = try values.decode(String.self, forKey: .language)
//    }
}

// Define colums so that we can build GRDB requests
extension User {
    enum Columns {
        static let uuid = Column("uuid")
        static let name = Column("name")
        static let email = Column("email")
        static let session = Column("session")
        static let pushNotifications = Column("pushNotifications")
        static let language = Column("language")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension User: FetchableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
extension User: MutablePersistableRecord {
    public static let databaseTableName = "user"
    public mutating func didInsert(with rowID: Int64, for column: String?) {
        userId = rowID
    }
}
