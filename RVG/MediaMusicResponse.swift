
import Foundation
import ObjectMapper

class MediaMusicResponse : Mappable {
    var media : [MediaMusic]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        media  <- map["result"]
    }
    
}
