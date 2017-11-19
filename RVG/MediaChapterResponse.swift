
import Foundation
import ObjectMapper

class MediaChapterResponse : Mappable {
    var media : [MediaChapter]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        media  <- map["result"]
    }
    
}
