import Foundation
import Moya

enum KJVRVGService {
    case musicMedia(mid: String) // "/music/{mid}/media"
    case music
    case pushTokenUpdate(fcmToken: String, apnsToken: String, preferredLanguage: String, platform: String)
    case languagesSupported
    case gospels(languageId: String) // v1.1/gospels?language-id=en
    case gospelsMedia(gid: String) // v1.1/gospels/{gid}/media
    case booksChapterMedia(bid: String, languageId: String) // v1.1/books/{bid}/media?language-id=en
    case books(languageId: String) // v1.1/books?language-id=en
}

// echo '{"deviceUniqueIdentifier": "device-unique-identifier-value", "apnsToken": "apns-token-value", "fcmToken": "firebase-cloud-messaging-token-value", "nonce": "nonce-value"}' | http localhost:6543/v1/device/pushtoken/add

// MARK: - TargetType Protocol Implementation
extension KJVRVGService: TargetType {
    
    var baseURL: URL { return URL(string: "\(EnvironmentUrlItemKey.DevelopmentServerRootUrl.rawValue)/v1.2")! }
    //    var baseURL: URL { return URL(string: "http://localhost:6543/v1")! }
    var path: String {
        switch self {
        case .musicMedia(let mid):
            return "/music/\(mid)/media"
        case .music:
            return "/music"
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
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .musicMedia,
             .music,
             .booksChapterMedia,
             .languagesSupported,
             .gospels,
             .gospelsMedia,
             .books:
            return .get
        case .pushTokenUpdate:
            return .post
        }
    }
    var parameters: [String: Any]? {
        switch self {
        case .musicMedia(_):
            return nil
        case .music:
            return nil
        case .booksChapterMedia(_, let languageId):
            return ["language-id": languageId]
        case .books(let languageId):
            return ["language-id": languageId]
        case .gospelsMedia(_):
            return nil
        case .gospels(let languageId):
            return ["language-id": languageId]
        case .languagesSupported:
            return nil
        case .pushTokenUpdate(let fcmToken,
                              let apnsToken,
                              let preferredLanguage,
                              let platform):
            return ["fcmToken": fcmToken,
                    "apnsToken": apnsToken,
                    "preferredLanguage": preferredLanguage,
                    "platform": platform]
        }
    }
    var parameterEncoding: ParameterEncoding {
        switch self {
        case .musicMedia,
             .music,
             .booksChapterMedia,
             .languagesSupported,
             .gospels,
             .gospelsMedia,
             .books:
            return URLEncoding.default // Send parameters in URL for GET, DELETE and HEAD. For other HTTP methods, parameters will be sent in request body
        case .pushTokenUpdate:
            return JSONEncoding.default // Send parameters as JSON in request body
        }
    }
    var sampleData: Data {
        switch self {
        case .musicMedia(let mid):
            return "{\"mid\": \(mid),\"}".utf8Encoded
        case .music:
            return "foobar".utf8Encoded
        case .pushTokenUpdate(let fcmToken,
                              let apnsToken,
                              let preferredLanguage,
                              let platform):
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
        case .languagesSupported:
            return "Half measures are as bad as nothing at all.".utf8Encoded
        }
    }
    var task: Task {
        switch self {
        case .musicMedia(let mid):
            return .requestParameters(parameters:  ["mid": mid],
                                      encoding: URLEncoding.default)
        case .music:
            return .requestPlain
        case .books(let languageId):
            return .requestParameters(parameters:  ["language-id": languageId],
                                      encoding: URLEncoding.default)
        case .pushTokenUpdate(let fcmToken, let apnsToken, let preferredLanguage, let platform):
            return .requestParameters(parameters:  ["fcmToken": fcmToken,
                                                    "apnsToken": apnsToken,
                                                    "preferredLanguage": preferredLanguage,
                                                    "platform": platform],
                                      encoding: JSONEncoding.default)
        case .languagesSupported:
            return .requestPlain
        case .booksChapterMedia(let bid, let languageId):
            return .requestParameters(parameters:  ["bid": bid,
                                                    "language-id": languageId],
                                      encoding: URLEncoding.default)
        case .gospels(let languageId):
            return .requestParameters(parameters:  ["language-id": languageId],
                                      encoding: URLEncoding.default)
        case .gospelsMedia(let gid):
            return .requestParameters(parameters:  ["gid": gid],
                                      encoding: URLEncoding.default)
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
