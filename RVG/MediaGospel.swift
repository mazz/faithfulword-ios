import Foundation
public struct MediaGospel: Codable, Playable {
    //    var bookId: Int64?
    //    var userId: Int64?
    public var uuid: String
    public var localizedName: String?
    public var path: String?
    public var presenterName: String?
    public var sourceMaterial: String?
}
