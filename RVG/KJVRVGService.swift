import Foundation
import Moya

enum KJVRVGService {
    case booksLocalizedTitles(languageId: String)
    case pushTokenUpdate(fcmToken: String)
    case books
    case zen
    case showUser(id: Int)
    case createUser(firstName: String, lastName: String)
    case updateUser(id:Int, firstName: String, lastName: String)
    case showAccounts
}

// echo '{"deviceUniqueIdentifier": "device-unique-identifier-value", "apnsToken": "apns-token-value", "fcmToken": "firebase-cloud-messaging-token-value", "nonce": "nonce-value"}' | http localhost:6543/v1/device/pushtoken/add

// MARK: - TargetType Protocol Implementation
extension KJVRVGService: TargetType {
    var baseURL: URL { return URL(string: "https://japheth.ca/v1.1")! }
    //    var baseURL: URL { return URL(string: "http://localhost:6543/v1")! }
    var path: String {
        switch self {
        case .booksLocalizedTitles(_):
            return "/books/titles/localized"
        case .pushTokenUpdate(_):
            return "/device/pushtoken/set"
        case .books:
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
        case .booksLocalizedTitles, .books, .zen, .showUser, .showAccounts:
            return .get
        case .pushTokenUpdate, .createUser, .updateUser:
            return .post
        }
    }
    var parameters: [String: Any]? {
        switch self {
        case .booksLocalizedTitles(let languageId):
            return ["language-id": languageId]
        case .books, .zen, .showUser, .showAccounts:
            return nil
        case .createUser(let firstName, let lastName), .updateUser(_, let firstName, let lastName):
            return ["first_name": firstName, "last_name": lastName]
        case .pushTokenUpdate(let fcmToken):
            return ["fcmToken": fcmToken]
        }
    }
    var parameterEncoding: ParameterEncoding {
        switch self {
        case .books, .zen, .showUser, .showAccounts:
            return URLEncoding.default // Send parameters in URL for GET, DELETE and HEAD. For other HTTP methods, parameters will be sent in request body
        case .booksLocalizedTitles, .updateUser:
            return URLEncoding.queryString // Always sends parameters in URL, regardless of which HTTP method is used
        case .pushTokenUpdate, .createUser:
            return JSONEncoding.default // Send parameters as JSON in request body
        }
    }
    var sampleData: Data {
        switch self {
        case .booksLocalizedTitles(let languageId):
            return "{\"language-id\": \"\(languageId)\"}".utf8Encoded
        case .pushTokenUpdate(let fcmToken):
            let pushTokenJson = [
                "fcmToken": fcmToken
            ]
            return jsonSerializedUTF8(json: pushTokenJson)
        case .books:
            return "{\n    \"result\": [\n        {\n            \"bid\": \"e931ea58-080f-46ee-ae21-3bbec0365ddc\",\n            \"title\": \"Matthew\"\n        },\n        {\n            \"bid\": \"e5612c8e-5d77-4e95-b462-4f7c1d90ad80\",\n            \"title\": \"Mark\"\n        },\n        {\n            \"bid\": \"42791fe3-4a41-46a3-b8a4-309936389c70\",\n            \"title\": \"Luke\"\n        },\n        {\n            \"bid\": \"3d94e17e-1c57-4012-b982-4740a93b2a4a\",\n            \"title\": \"John\"\n        }\n    ],\n    \"status\": \"success\",\n    \"version\": \"1\"\n}".utf8Encoded
        case .zen:
            return "Half measures are as bad as nothing at all.".utf8Encoded
        case .showUser(let id):
            return "{\"id\": \(id), \"first_name\": \"Harry\", \"last_name\": \"Potter\"}".utf8Encoded
        case .createUser(let firstName, let lastName):
            return "{\"id\": 100, \"first_name\": \"\(firstName)\", \"last_name\": \"\(lastName)\"}".utf8Encoded
        case .updateUser(let id, let firstName, let lastName):
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
        case .booksLocalizedTitles, .pushTokenUpdate, .books, .zen, .showUser, .createUser, .updateUser, .showAccounts:
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
