import Foundation
import Moya

enum KJVRVGService {
    case pushTokenUpdate(fcmToken: String, apnsToken: String, preferredLanguage: String, platform: String)
    case languagesSupported
    case gospels(languageId: String) // v1.1/gospels?language-id=en
    case gospelsMedia(gid: String) // v1.1/gospels/{gid}/media
    case booksChapterMedia(bid: String, languageId: String) // v1.1/books/{bid}/media?language-id=en
    case books(languageId: String) // v1.1/books?language-id=en
    case zen
    case showUser(id: Int)
    case createUser(firstName: String, lastName: String)
    case updateUser(id:Int, firstName: String, lastName: String)
    case showAccounts
}

// echo '{"deviceUniqueIdentifier": "device-unique-identifier-value", "apnsToken": "apns-token-value", "fcmToken": "firebase-cloud-messaging-token-value", "nonce": "nonce-value"}' | http localhost:6543/v1/device/pushtoken/add

// MARK: - TargetType Protocol Implementation
extension KJVRVGService: TargetType {
    
    var baseURL: URL { return URL(string: "\(EnvironmentUrlItemKey.DevelopmentServerRootUrl.rawValue)/v1.2")! }
    //    var baseURL: URL { return URL(string: "http://localhost:6543/v1")! }
    var path: String {
        switch self {
        case .pushTokenUpdate(_, _, _, _):
            return "/device/pushtoken/update"
        case .languagesSupported:
            return "/languages/supported"
        case .gospels(_):
            return "/gospels"
        case .gospelsMedia(let gid):
            return "/gospels/\(gid)/media"
        case .booksChapterMedia(let bid, _):
            return "/books/\(bid)/media"
        case .books(_):
            return "/books"
        case .zen:
            return "/zen"
        case .showUser(let id), .updateUser(let id, _, _):
            return "/users/\(id)"
        case .createUser(_, _):
            return "/users"
        case .showAccounts:
            return "/accounts"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .booksChapterMedia, .languagesSupported, .gospels, .gospelsMedia, .books, .zen, .showUser, .showAccounts:
            return .get
        case .pushTokenUpdate, .createUser, .updateUser:
            return .post
        }
    }
    var parameters: [String: Any]? {
        switch self {
        case .booksChapterMedia(_, let languageId):
            return ["language-id": languageId]
        case .books(let languageId):
            return ["language-id": languageId]
        case .gospelsMedia(_):
            return nil
        case .gospels(let languageId):
            return ["language-id": languageId]
        case .languagesSupported, .zen, .showUser, .showAccounts:
            return nil
        case .createUser(let firstName, let lastName), .updateUser(_, let firstName, let lastName):
            return ["first_name": firstName, "last_name": lastName]
        case .pushTokenUpdate(let fcmToken, let apnsToken, let preferredLanguage, let platform):
            return ["fcmToken": fcmToken, "apnsToken": apnsToken, "preferredLanguage": preferredLanguage, "platform": platform]
        }
    }
    var parameterEncoding: ParameterEncoding {
        switch self {
        case .booksChapterMedia, .languagesSupported, .gospels, .gospelsMedia, .books, .zen, .showUser, .showAccounts:
            return URLEncoding.default // Send parameters in URL for GET, DELETE and HEAD. For other HTTP methods, parameters will be sent in request body
        case .updateUser:
            return URLEncoding.queryString // Always sends parameters in URL, regardless of which HTTP method is used
        case .pushTokenUpdate, .createUser:
            return JSONEncoding.default // Send parameters as JSON in request body
        }
    }
    var sampleData: Data {
        switch self {
        case .pushTokenUpdate(let fcmToken, let apnsToken, let preferredLanguage, let platform):
            let pushTokenJson = [
                "fcmToken": fcmToken,
                "apnsToken": apnsToken,
                "preferredLanguage": preferredLanguage,
                "platform": platform
            ]
            return jsonSerializedUTF8(json: pushTokenJson)
        case .booksChapterMedia(let bid, let languageId):
            return "{\"bid\": \(bid), \"language-id\": \"\(languageId)\"}".utf8Encoded
        case .gospels(let languageId):
            return "{\"language-id\": \"\(languageId)\"}".utf8Encoded
        case .gospelsMedia(let gid):
            return "{\"gid\": \(gid),\"}".utf8Encoded
        case .books(let languageId):
            return "{\"language-id\": \"\(languageId)\"}".utf8Encoded
        case .languagesSupported, .zen:
            return "Half measures are as bad as nothing at all.".utf8Encoded
        case .showUser(let id):
            return "{\"id\": \(id), \"first_name\": \"Harry\", \"last_name\": \"Potter\"}".utf8Encoded
        case .createUser(let firstName, let lastName):
            return "{\"id\": 100, \"first_name\": \"\(firstName)\", \"last_name\": \"\(lastName)\"}".utf8Encoded
        case .updateUser(let id, let firstName, let lastName): // // POST https://api.myservice.com/users/123?first_name=Harry&last_name=Potter
            return "{\"id\": \(id), \"first_name\": \"\(firstName)\", \"last_name\": \"\(lastName)\"}".utf8Encoded
        case .showAccounts:
            // Provided you have a file named accounts.json in your bundle.
            guard let url = Bundle.main.url(forResource: "accounts", withExtension: "json"),
                let data = try? Data(contentsOf: url) else {
                    return Data()
            }
            return data
        }
    }
    var task: Task {
        switch self {
        case .pushTokenUpdate,
             .languagesSupported,
             .booksChapterMedia,
             .gospels,
             .gospelsMedia,
             .books,
             .zen,
             .showUser,
             .createUser,
             .updateUser,
             .showAccounts:
            return .request
        }
    }
    
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
    
    // Helper
    private func jsonSerializedUTF8(json: [String: Any]) -> Data {
        return try! JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted]
        )
    }
}

// MARK: - Helpers
private extension String {
    var urlEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
    
    var utf8Encoded: Data {
        return self.data(using: .utf8)!
    }
}
