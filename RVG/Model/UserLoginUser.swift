import Foundation
import GRDB

public struct UserLoginUser: Codable {
    public var achievements: [Int]
    public var email: String
    public var email_confirmed: Bool
    public var fb_user_id: Int?
    public var id: Int
    public var org_id: Int
    public var is_publisher: Bool
    public var locale: String
    public var mini_picture_url: String?
    public var name: String
    public var picture_url: String?
    public var registered_at: TimeInterval
    public var reputation: Int
    public var username: String
    public var uuid: String

//    enum CodingKeys: String, CodingKey {
//        case achievements
//        case email
//        case fb_user_id
//        case id
//        case is_publisher
//        case locale
//        case mini_picture_url
//        case name
//        case picture_url
//        case registered_at
//        case reputation
//        case username
//    }

//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//
//        try container.encode(achievements, forKey: .achievements)
//        try container.encode(email, forKey: .email)
//        try container.encode(fb_user_id, forKey: .fb_user_id)
//        try container.encode(id, forKey: .id)
//        try container.encode(is_publisher, forKey: .is_publisher)
//        try container.encode(locale, forKey: .locale)
//        try container.encode(mini_picture_url, forKey: .mini_picture_url)
//        try container.encode(name, forKey: .name)
//        try container.encode(picture_url, forKey: .picture_url)
//        try container.encode(registered_at, forKey: .registered_at)
//        try container.encode(reputation, forKey: .reputation)
//        try container.encode(username, forKey: .username)
//    }
//
//    public init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//
//        self.achievements = try values.decode([Int].self, forKey: .achievements)
//        self.email = try values.decode(String.self, forKey: .email)
//
//        self.fb_user_id = try? values.decode(Int.self, forKey: .fb_user_id)
//        self.id = try values.decode(Int.self, forKey: .id)
//        self.is_publisher = try values.decode(Bool.self, forKey: .is_publisher)
//
//        self.locale = try? values.decode(String.self, forKey: .locale)
//        self.mini_picture_url = try? values.decode(String.self, forKey: .mini_picture_url)
//        self.name = try? values.decode(String.self, forKey: .name)
//        self.picture_url = try? values.decode(String.self, forKey: .picture_url)
//
//        // 2019-06-22T14:17:10Z
//        let stringDate: String = try values.decode(String.self, forKey: .registered_at)
//        let formatter = DateFormatter()
//        formatter.locale = Locale(identifier: "en_US_POSIX")
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
//        self.registered_at = formatter.date(from: stringDate) ?? Date()
//
//        self.reputation = try values.decode(Int.self, forKey: .reputation)
//        self.username = try values.decode(String.self, forKey: .username)
//    }
    
}

// Define columns so that we can build GRDB requests
extension UserLoginUser {
    enum Columns {
        static let achievements = Column("achievements")
        static let email = Column("email")
        static let email_confirmed = Column("email_confirmed")
        static let fb_user_id = Column("fb_user_id")
        static let id = Column("id")
        static let org_id = Column("org_id")
        static let is_publisher = Column("is_publisher")
        static let locale = Column("locale")
        static let mini_picture_url = Column("mini_picture_url")
        static let name = Column("name")
        static let picture_url = Column("picture_url")
        static let registered_at = Column("registered_at")
        static let reputation = Column("reputation")
        static let username = Column("username")
        static let uuid = Column("uuid")
    }
}

extension UserLoginUser: FetchableRecord, PersistableRecord { }

