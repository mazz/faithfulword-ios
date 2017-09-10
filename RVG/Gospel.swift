import Foundation
import ObjectMapper

class Gospel : Mappable {
    var gospelId : String?
    var title : String?
    var localizedTitle : String?
    var languageId : String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        gospelId  <- map["gid"]
        title  <- map["title"]
        languageId  <- map["languageId"]
        localizedTitle  <- map["localizedTitle"]
    }
}
