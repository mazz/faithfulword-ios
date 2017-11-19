
import Foundation
import ObjectMapper

class BookResponse : Mappable {
    var books : [Book]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        books  <- map["result"]
    }
    
}
