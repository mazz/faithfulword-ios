import Foundation
import ObjectMapper

class Book : Mappable {
    var bookId : String?
    var title : String?
    var localizedTitle : String?
    var languageId : String?
    
    required init?(map: Map) {
    
    }

    func mapping(map: Map) {
        bookId  <- map["bid"]
        title  <- map["title"]
        languageId  <- map["languageId"]
        localizedTitle  <- map["localizedTitle"]
    }
    
}

