import Foundation
import GRDB

public struct UserAppUser: Codable {
    public var userId: Int
    public var uuid: String
    public var orgId: Int
    public var name: String
    public var email: String
    public var session: String
    public var pushNotifications: Bool
    public var language: String
    public var userLoginUserUuid: String?


    //
    // a UserAppUser is one-to-one to UserLoginUser
    //
    static let userLoginUserForeignKey = ForeignKey([Columns.userLoginUserUuid])

    //
    // a User is one-to-many to FileDownload
    //
//    static let downloads = hasMany(FileDownload.self, using: FileDownload.downloaditemForeignKey)

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
extension UserAppUser {
    enum Columns {
        static let userId = Column("userId")
        static let uuid = Column("uuid")
        static let orgId = Column("orgId")
        static let name = Column("name")
        static let email = Column("email")
        static let session = Column("session")
        static let pushNotifications = Column("pushNotifications")
        static let language = Column("language")
        static let userLoginUserUuid = Column("userLoginUserUuid")
    }
}

// Adopt RowConvertible so that we can fetch players from the database.
// Implementation is automatically derived from Codable.
extension UserAppUser: FetchableRecord, PersistableRecord { }

// Adopt MutablePersistable so that we can create/update/delete players in the database.
// Implementation is partially derived from Codable.
//extension User: MutablePersistableRecord {
//    public static let databaseTableName = "user"
//    public mutating func didInsert(with rowID: Int64, for column: String?) {
//        userId = rowID
//    }
//}
