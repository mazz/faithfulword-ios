import Foundation
import Moya

public enum FwbcApiService {
    case appVersions(offset: Int, limit: Int)
    case pushTokenUpdate(fcmToken: String, apnsToken: String, preferredLanguage: String, userAgent: String, userVersion: String)
    // v1.1/languages/supported
    // v1.2/languages/supported
    // v1.3/languages/supported?offset=1&limit=50
    case languagesSupported(offset: Int, limit: Int)
    // v1.3/orgs/default?offset=1&limit=50
    case defaultOrgs(offset: Int, limit: Int)
    
    // v1.3/orgs/{uuid}/channels?language-id=en&offset=1&limit=50
    case channels(uuid: String, offset: Int, limit: Int)
    
    // v1.3/channels/{uuid}/playlists?language-id=en&offset=1&limit=50
    case playlists(uuid: String, languageId: String, offset: Int, limit: Int)
    
    // v1.3/playlists/{uuid}/media?language-id=en&offset=1&limit=50
    case mediaItems(uuid: String, languageId: String, offset: Int, limit: Int)
    
    // v1.3/search
    case search(query: String,
        mediaCategory: String,
        playlistUuid: String,
        channelUuid: String,
        publishedAfter: TimeInterval,
        updatedAfter: TimeInterval,
        presentedAfter: TimeInterval,
        offset: Int,
        limit: Int)
    
    // v1.1/music/{gid}/media
    // v1.2/music/{gid}/media
    // v1.3/music/{uuid}/media?language-id=en&offset=1&limit=50
    case musicMedia(uuid: String, offset: Int, limit: Int)
    // v1.1/music?language-id=en
    // v1.2/music?language-id=en
    // v1.3/music?language-id=en&offset=1&limit=50
    case music(languageId: String, offset: Int, limit: Int)
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
        case .pushTokenUpdate(_, _, _, _, _):
            return "/device/pushtoken/update"
        case .appVersions(_, _):
            return "/app/versions"
        case .languagesSupported(_, _):
            return "/languages/supported"
        case .defaultOrgs(_, _):
            return "/orgs/default"
            
        case .channels(let uuid, _, _):
            return "/orgs/\(uuid)/channels"
        case .playlists(let uuid, _, _, _):
            return "/channels/\(uuid)/playlists"
        case .mediaItems(let uuid, _, _, _):
            return "/playlists/\(uuid)/media"
        case .search(_, _, _, _, _, _, _, _, _):
            return "/search"
            
            
        case .musicMedia(let uuid, _, _):
            return "/music/\(uuid)/media"
        case .music(_, _, _):
            return "/music"
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
        case .appVersions:
            return .get
        case .languagesSupported:
            return .get
        case .defaultOrgs:
            return .get
            
        case .channels:
            return .get
        case .playlists:
            return .get
        case .mediaItems:
            return .get
        case .search:
            return .post
            
            
        case .musicMedia:
            return .get
        case .music:
            return .get
        case .booksChapterMedia:
            return .get
        case .gospels:
            return .get
        case .gospelsMedia:
            return .get
        case .books:
            return .get
        case .pushTokenUpdate:
            return .post
        }
    }
    public var parameters: [String: Any]? {
        switch self {
        case .appVersions(let offset, let limit):
            return ["offset": offset,
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
        case .languagesSupported(let offset, let limit):
            return ["offset": offset,
                    "limit": limit]
        case .defaultOrgs(let offset, let limit):
            return ["offset": offset,
                    "limit": limit]
            
        case .channels(_, let offset, let limit):
            return ["offset": offset, "limit": limit]
        case .playlists(_, let languageId, let offset, let limit):
            return ["language-id": languageId, "offset": offset, "limit": limit]
        case .mediaItems(_, let languageId, let offset, let limit):
            return ["language-id": languageId, "offset": offset, "limit": limit]
        case .search(let query,
                     let mediaCategory,
                     let playlistUuid,
                     let channelUuid,
                     let publishedAfter,
                     let updatedAfter,
                     let presentedAfter,
                     let offset,
                     let limit):
            return ["query": query,
                    "mediaCategory": mediaCategory,
                    "playlistUuid": playlistUuid,
                    "channelUuid": channelUuid,
                    "publishedAfter": publishedAfter,
                    "updatedAfter": updatedAfter,
                    "presentedAfter": presentedAfter,
                    "offset": offset,
                    "limit": limit]
            
            //        case search(query: String,
            //                    mediaCategory: String,
            //                    playlistUuid: String,
            //                    channelUuid: String,
            //                    publishedAfter: TimeInterval,
            //                    updatedAfter: TimeInterval,
            //                    presentedAfter: TimeInterval,
            //                    offset: Int,
            //                    limit: Int)
            
            
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
        }
    }
    public var parameterEncoding: ParameterEncoding {
        switch self {
        case .appVersions:
            return URLEncoding.default
        case .pushTokenUpdate:
            return JSONEncoding.default // Send parameters as JSON in request body
        case .languagesSupported:
            return URLEncoding.default
        case .defaultOrgs:
            return URLEncoding.default // Send parameters in URL for GET, DELETE and HEAD. For other HTTP methods, parameters will be sent in request body
        case .channels:
            return URLEncoding.default
        case .playlists:
            return URLEncoding.default
        case .mediaItems:
            return URLEncoding.default
        case .search:
            return JSONEncoding.default // Send parameters as JSON in request body
            
        case .musicMedia(let uuid, let offset, let limit):
            return URLEncoding.default
        case .music(let languageId, let offset, let limit):
            return URLEncoding.default
        case .gospels(let languageId, let offset, let limit):
            return URLEncoding.default
        case .gospelsMedia(let uuid, let offset, let limit):
            return URLEncoding.default
        case .booksChapterMedia(let uuid, let languageId, let offset, let limit):
            return URLEncoding.default
        case .books(let languageId, let offset, let limit):
            return URLEncoding.default
        }
    }
    public var sampleData: Data {
        switch self {
        case .appVersions(let offset, let limit):
            return "{\"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
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
        case .languagesSupported(let offset, let limit):
            return "{\"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
        case .defaultOrgs(let offset, let limit):
            return "{\"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
            
        case .channels(let uuid, let offset, let limit):
            return "{\"uuid\": \(uuid), \"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
        case .playlists(let uuid, let languageId, let offset, let limit):
            return "{\"uuid\": \(uuid), \"language-id\": \"\(languageId)\", \"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
        case .mediaItems(let uuid, let languageId, let offset, let limit):
            return "{\"uuid\": \(uuid), \"language-id\": \"\(languageId)\", \"offset\": \"\(offset)\", \"limit\": \"\(limit)\"}".utf8Encoded
            
        case .search(let query,
                     let mediaCategory,
                     let playlistUuid,
                     let channelUuid,
                     let publishedAfter,
                     let updatedAfter,
                     let presentedAfter,
                     let offset,
                     let limit):
            return "{\"query\": \(query), \"mediaCategory\": \(mediaCategory), \"playlistUuid\": \(playlistUuid), \"channelUuid\": \(channelUuid), \"publishedAfter\": \(publishedAfter), \"updatedAfter\": \(updatedAfter), \"presentedAfter\": \(presentedAfter), \"offset\": \(offset), \"limit\": \(limit)}".utf8Encoded
            
            
            
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
        }
    }
    public var task: Task {
        switch self {
        case .appVersions(let offset, let limit):
            return .requestParameters(parameters:  ["offset": offset,
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
        case .defaultOrgs(let offset, let limit):
            return .requestParameters(parameters:  ["offset": offset,
                                                    "limit": limit],
                                      encoding: URLEncoding.default)
            
        case .channels(_, let offset, let limit):
            return .requestParameters(parameters: [ "offset": offset,
                                                    "limit": limit],
                                      encoding: URLEncoding.default)
        case .playlists(_, let languageId, let offset, let limit):
            return .requestParameters(parameters: ["language-id": languageId,
                                                    "offset": offset,
                                                    "limit": limit],
                                      encoding: URLEncoding.default)
        case .mediaItems(_, let languageId, let offset, let limit):
            return .requestParameters(parameters: ["language-id": languageId,
                                                   "offset": offset,
                                                   "limit": limit],
                                      encoding: URLEncoding.default)

        case .search(let query,
                     let mediaCategory,
                     let playlistUuid,
                     let channelUuid,
                     let publishedAfter,
                     let updatedAfter,
                     let presentedAfter,
                     let offset,
                     let limit):
            return .requestParameters(parameters:  ["query": query,
                                                    "mediaCategory": mediaCategory,
                                                    "playlistUuid": playlistUuid,
                                                    "channelUuid": channelUuid,
                                                    "publishedAfter": publishedAfter,
                                                    "updatedAfter": updatedAfter,
                                                    "presentedAfter": presentedAfter,
                                                    "offset": offset,
                                                    "limit": limit],
                                      encoding: JSONEncoding.default)
            
            
            
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
