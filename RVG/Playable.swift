import Foundation

/*
 "localizedName": "Are You Washed in the Blood #22",
 "path": "music/fwbc/v1TheCross/0001-0001-AreYouWashedintheBlood-en.mp3",
 "sourceMaterial": "Soul Stirring Songs and Hymns",
 "presenterName": "FWBC",
 "uuid": "99d6d4a7-1707-465f-9814-0744be512da4",
 "trackNumber": 1,
 "createdAt": "2018-04-17 02:04:13",
 "largeThumbnailPath": null,
 "updatedAt": null,
 "smallThumbnailPath": null
*/

public protocol Playable {
    var uuid: String { get set }
    var localizedName : String? { get set }
    var path : String? { get set }
    var presenterName : String? { get set }
    var sourceMaterial : String? { get set }
    var trackNumber : Int64? { get set }
    var createdAt : Date? { get set }
    var updatedAt : Date? { get set }
    var largeThumbnailPath : String? { get set }
    var smallThumbnailPath : String? { get set }
}

enum MediaType {
    case audioChapter
    case audioSermon
    case audioGospel
    case audioMusic
}
