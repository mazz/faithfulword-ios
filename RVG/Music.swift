
import Foundation
import ObjectMapper

class Music : Mappable {
    var musicId : String?
    var title : String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        musicId  <- map["mid"]
        title  <- map["title"]
    }
    
}
