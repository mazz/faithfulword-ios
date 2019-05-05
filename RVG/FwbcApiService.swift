import Foundation
import Moya

public enum FwbcApiService {
    case churches
    case churchesMediaSermons(cid: String)
    case appVersions
    case pushTokenUpdate(fcmToken: String, apnsToken: String, preferredLanguage: String, userAgent: String, userVersion: String)
    // v1.1/music/{gid}/media
    // v1.2/music/{gid}/media
    // v1.3/music/{uuid}/media?language-id=en&offset=1&limit=50
    case musicMedia(uuid: String, offset: Int, limit: Int)
    // v1.1/music?language-id=en
    // v1.2/music?language-id=en
    // v1.3/music?language-id=en&offset=1&limit=50
    case music(languageId: String, offset: Int, limit: Int)
    // v1.1/languages/supported
    // v1.2/languages/supported
    // v1.3/languages/supported?offset=1&limit=50
    case languagesSupported(offset: Int, limit: Int)
    // v1.1/gospels?language-id=en
    // v1.2/gospels?language-id=en
    // v1.3/gospels?language-id=en&offset=1&limit=50
    case gospels(languageId: String, offset: Int, limit: Int)
    // v1.1/gospels/{gid}/media
    // v1.2/gospels/{gid}/media
    // v1.3/gospels/{uuid}/media?language-id=en&offset=1&limit=50
    case gospelsMedia(uuid: String, offset: Int, limit: Int)
    // v1.1/books/{bid}/media?language-id=en
    // v1.2/books/{bid}/media?language-id=en
    // v1.3/books/{uuid}/media?language-id=en&offset=1&limit=50
    case booksChapterMedia(uuid: String, languageId: String, offset: Int, limit: Int)
    // v1.1/books?language-id=en
    // v1.2/books?language-id=en
    // v1.3/books?language-id=en&offset=1&limit=50
    case books(languageId: String, offset: Int, limit: Int)
}


// MARK: - TargetType Protocol Implementation
extension FwbcApiService: TargetType {
    
    //    public var baseURL: URL { return URL(string: "\(EnvironmentUrlItemKey.LocalServerRootUrl.rawValue)/v2.0")! }
    public var baseURL: URL { return URL(string: "\(EnvironmentUrlItemKey.DevelopmentServerRootUrl.rawValue)/v1.3")! }
    //    public var baseURL: URL { return URL(string: "\(EnvironmentUrlItemKey.LocalServerRootUrl.rawValue)/v1.3")! }
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
        case .musicMedia(let uuid, _, _):
            return "/music/\(uuid)/media"
        case .music(_, _, _):
            return "/music"
        case .languagesSupported(_, _):
            return "/languages/supported"
        case .gospels(_, _, _):
            return "/gospels"
        case .gospelsMedia(let uuid, _, _):
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
        case .languagesSupported(let offset, let limit):
            return ["offset": offset,
                    "limit": limit]
        case .musicMedia(_, let offset, let limit):
            return ["offset": offset, "limit": limit]
        case .music(let languageId, let offset, let limit):
            return ["language-id": languageId,
                    "offset": offset,
                    "limit": limit]
        case .booksChapterMedia(_, let languageId, let offset, let limit):
            return ["language-id": languageId, "offset": offset, "limit": limit]
        case .books(let languageId, let offset, let limit):
            return ["language-id": languageId, "offset": offset, "limit": limit]
        case .gospelsMedia(_, let offset, let limit):
            return ["offset": offset, "limit": limit]
        case .gospels(let languageId, let offset, let limit):
            return ["language-id": languageId,
                    "offset": offset,
                    "limit": limit]
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
        case .gospels(let languageId, let offset, let limit):
            return "{\"language-id\": \"\(languageId)\", \"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
        case .gospelsMedia(let uuid, let offset, let limit):
            return "{\"uuid\": \(uuid), \"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
        case .musicMedia(let uuid, let offset, let limit):
            return "{\"uuid\": \(uuid), \"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
        case .music(let languageId, let offset, let limit):
            return "{\"language-id\": \"\(languageId)\", \"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
        case .books(let languageId, let offset, let limit):
            return "{\"language-id\": \"\(languageId)\", \"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
        case .languagesSupported(let offset, let limit):
            return "{\"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
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
        case .musicMedia(let uuid, let offset, let limit):
            return .requestParameters(parameters:  ["uuid": uuid,
                                                    "offset": offset,
                                                    "limit": limit],
                                      encoding: URLEncoding.default)
        case .music(let languageId, let offset, let limit):
            return .requestParameters(parameters:  ["language-id": languageId,
                                                    "offset": offset,
                                                    "limit": limit],
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
        case .languagesSupported(let offset, let limit):
            return .requestParameters(parameters:  ["offset": offset,
                                                    "limit": limit],
                                      encoding: URLEncoding.default)
        case .booksChapterMedia(let uuid, let languageId, let offset, let limit):
            return .requestParameters(parameters:  ["uuid": uuid,
                                                    "language-id": languageId,
                                                    "offset": offset,
                                                    "limit": limit],
                                      encoding: URLEncoding.default)
        case .gospels(let languageId, let offset, let limit):
            return .requestParameters(parameters:  ["language-id": languageId,
                                                    "offset": offset,
                                                    "limit": limit],
                                      encoding: URLEncoding.default)
        case .gospelsMedia(let uuid, let offset, let limit):
            return .requestParameters(parameters:  ["uuid": uuid,
                                                    "offset": offset,
                                                    "limit": limit],
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
