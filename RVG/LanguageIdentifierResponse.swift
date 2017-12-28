
import Foundation
import ObjectMapper

class LanguageIdentifierResponse : Mappable {
    var languageIdentifiers : [LanguageIdentifier]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        languageIdentifiers  <- map["result"]
    }
    
}
