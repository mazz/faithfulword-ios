import Foundation
import ObjectMapper

class BookTitleResponse : Mappable {
    var bookTitles : [BookTitle]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        bookTitles  <- map["result"]
    }
    
}
