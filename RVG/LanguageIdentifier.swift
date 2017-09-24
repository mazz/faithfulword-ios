import Foundation
import ObjectMapper

class LanguageIdentifier : Mappable {
    var languageIdentifier : String?
    var supported : Bool?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        languageIdentifier  <- map["languageIdentifier"]
        supported <- map["supported"]
    }
    
    
}
