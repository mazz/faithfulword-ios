
import Foundation
import ObjectMapper

class MediaGospelResponse : Mappable {
    var media : [MediaGospel]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        media  <- map["result"]
    }
    
}
