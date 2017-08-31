import Foundation
import ObjectMapper

class BookTitle : Mappable {
    var basename : String?
    var languageId : String?
    var localizedName : String?
    
    required init?(map: Map) {
    
    }

    func mapping(map: Map) {
        basename  <- map["basename"]
        languageId  <- map["languageId"]
        localizedName  <- map["localizedName"]
    }
    
}
