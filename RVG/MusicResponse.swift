
import Foundation
import ObjectMapper

class MusicResponse : Mappable {
    var music : [Music]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        music  <- map["result"]
    }
    
}
