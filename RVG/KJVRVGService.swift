import Foundation
import Moya

public enum KJVRVGService {
    case churches
    case churchesMediaSermons(cid: String)
    case appVersions
    case pushTokenUpdate(fcmToken: String, apnsToken: String, preferredLanguage: String, userAgent: String, userVersion: String)
    case musicMedia(uuid: String) // "/music/{mid}/media"
    case music(languageId: String)
    case languagesSupported
    case gospels(languageId: String) // v1.1/gospels?language-id=en
    case gospelsMedia(uuid: String) // v1.1/gospels/{gid}/media
    // v1.1/books/{bid}/media?language-id=en
    // v1.2/books/{bid}/media?language-id=en
    // v1.3/books/{bid}/media?language-id=en&offset=1&limit=50
    case booksChapterMedia(uuid: String, languageId: String, offset: Int, limit: Int)
    // v1.1/books?language-id=en
    // v1.2/books?language-id=en
    // v1.3/books?language-id=en&offset=1&limit=50
    case books(languageId: String, offset: Int, limit: Int)
}


// MARK: - TargetType Protocol Implementation
extension KJVRVGService: TargetType {
    
//    public var baseURL: URL { return URL(string: "\(EnvironmentUrlItemKey.LocalServerRootUrl.rawValue)/v2.0")! }
    public var baseURL: URL { return URL(string: "\(EnvironmentUrlItemKey.DevelopmentServerRootUrl.rawValue)/v1.3")! }
    //    var baseURL: URL { return URL(string: "http://localhost:6543/v1")! }
    public var path: String {
        switch self {
        case .churches:
            return "/churches"
        case .churchesMediaSermons(let cid):
            return "/churches/\(cid)/media/sermon"
        case .pushTokenUpdate(_, _, _, _, _):
            return "/device/pushtoken/update"
        case .appVersions:
            return "/app/versions"
        case .musicMedia(let uuid):
            return "/music/\(uuid)/media"
        case .music(_):
            return "/music"
        case .languagesSupported:
            return "/languages/supported"
        case .gospels(_):
            return "/gospels"
        case .gospelsMedia(let uuid):
            return "/gospels/\(uuid)/media"
        case .booksChapterMedia(let uuid, _, _, _):
            return "/books/\(uuid)/media"
        case .books(_, _, _):
            return "/books"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .churches,
             .churchesMediaSermons,
             .appVersions,
             .languagesSupported,
             .musicMedia,
             .music,
             .booksChapterMedia,
             .gospels,
             .gospelsMedia,
             .books:
            return .get
        case .pushTokenUpdate:
            return .post
        }
    }
    public var parameters: [String: Any]? {
        switch self {
        case .churches:
            return nil
        case .churchesMediaSermons(_):
            return nil
        case .appVersions:
            return nil
        case .languagesSupported:
            return nil
        case .musicMedia(_):
            return nil
        case .music(let languageId):
            return ["language-id": languageId]
        case .booksChapterMedia(_, let languageId, let offset, let limit):
            return ["language-id": languageId, "offset": offset, "limit": limit]
        case .books(let languageId, let offset, let limit):
            return ["language-id": languageId, "offset": offset, "limit": limit]
        case .gospelsMedia(_):
            return nil
        case .gospels(let languageId):
            return ["language-id": languageId]
        case .pushTokenUpdate(let fcmToken,
                              let apnsToken,
                              let preferredLanguage,
                              let userAgent,
                              let userVersion):
            return ["fcmToken": fcmToken,
                    "apnsToken": apnsToken,
                    "preferredLanguage": preferredLanguage,
                    "userAgent": userAgent,
                    "userVersion": userVersion]
        }
    }
    public var parameterEncoding: ParameterEncoding {
        switch self {
        case .churches,
             .churchesMediaSermons,
             .appVersions,
             .languagesSupported,
             .musicMedia,
             .music,
             .booksChapterMedia,
             .gospels,
             .gospelsMedia,
             .books:
            return URLEncoding.default // Send parameters in URL for GET, DELETE and HEAD. For other HTTP methods, parameters will be sent in request body
        case .pushTokenUpdate:
            return JSONEncoding.default // Send parameters as JSON in request body
        }
    }
    public var sampleData: Data {
        switch self {
        case .churches:
            return "churches 1up".utf8Encoded
        case .churchesMediaSermons(let cid):
            return "{\"cid\": \(cid),\"}".utf8Encoded
        case .appVersions:
            return "app versions 1up".utf8Encoded
        case .pushTokenUpdate(let fcmToken,
                              let apnsToken,
                              let preferredLanguage,
                              let userAgent,
                              let userVersion):
            let pushTokenJson = [
                "fcmToken": fcmToken,
                "apnsToken": apnsToken,
                "preferredLanguage": preferredLanguage,
                "userAgent": userAgent,
                "userVersion": userVersion
            ]
            return jsonSerializedUTF8(json: pushTokenJson)
        case .booksChapterMedia(let uuid, let languageId, let offset, let limit):
            return "{\"uuid\": \(uuid), \"language-id\": \"\(languageId)\", \"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
        case .gospels(let languageId):
            return "{\"language-id\": \"\(languageId)\"}".utf8Encoded
        case .gospelsMedia(let uuid):
            return "{\"uuid\": \(uuid),\"}".utf8Encoded
        case .musicMedia(let uuid):
            return "{\"uuid\": \(uuid),\"}".utf8Encoded
        case .music(let languageId):
            return "{\"language-id\": \"\(languageId)\"}".utf8Encoded
        case .books(let languageId, let offset, let limit):
            return "{\"language-id\": \"\(languageId)\", \"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
        case .languagesSupported:
            return "Half measures are as bad as nothing at all.".utf8Encoded
        }
    }
    public var task: Task {
        switch self {
        case .churches:
            return .requestPlain
        case .churchesMediaSermons(let cid):
            return .requestParameters(parameters:  ["cid": cid],
                                      encoding: URLEncoding.default)
        case .appVersions:
            return .requestPlain
        case .musicMedia(let uuid):
            return .requestParameters(parameters:  ["uuid": uuid],
                                      encoding: URLEncoding.default)
        case .music(let languageId):
            return .requestParameters(parameters:  ["language-id": languageId],
                                      encoding: URLEncoding.default)
        case .books(let languageId, let offset, let limit):
            return .requestParameters(parameters:  ["language-id": languageId,
                                                    "offset": offset,
                                                    "limit": limit],
                                      encoding: URLEncoding.default)
        case .pushTokenUpdate(let fcmToken, let apnsToken, let preferredLanguage, let userAgent, let userVersion):
            return .requestParameters(parameters:  ["fcmToken": fcmToken,
                                                    "apnsToken": apnsToken,
                                                    "preferredLanguage": preferredLanguage,
                                                    "userAgent": userAgent,
                                                    "userVersion": userVersion],
                                      encoding: JSONEncoding.default)
        case .languagesSupported:
            return .requestPlain
        case .booksChapterMedia(let uuid, let languageId, let offset, let limit):
            return .requestParameters(parameters:  ["uuid": uuid,
                                                    "language-id": languageId,
                                                    "offset": offset,
                                                    "limit": limit],
                                      encoding: URLEncoding.default)
        case .gospels(let languageId):
            return .requestParameters(parameters:  ["language-id": languageId],
                                      encoding: URLEncoding.default)
        case .gospelsMedia(let uuid):
            return .requestParameters(parameters:  ["uuid": uuid],
                                      encoding: URLEncoding.default)
        }
    }
    
    public var headers: [String: String]? {
        return ["Content-type": "application/json",
                "User-Agent": Device.userAgent()]
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
