import Foundation
import ObjectMapper

class LanguagesSupportedResponse : Mappable {
    var languageIdentifiers : [LanguageIdentifier]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        languageIdentifiers  <- map["result"]
    }
    
}
