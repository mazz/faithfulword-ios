import Foundation

public struct LanguagesSupportedResponse: Codable {
    let result: [LanguageIdentifier]
    let version: String
    let status: String
}
