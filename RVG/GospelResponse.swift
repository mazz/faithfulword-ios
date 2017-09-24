import Foundation
import ObjectMapper

class GospelResponse : Mappable {
    var gospels : [Gospel]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        gospels  <- map["result"]
    }
    
}
