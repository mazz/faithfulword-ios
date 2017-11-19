
import Foundation
import ObjectMapper

class MediaChapter : Mappable, Playable {
    var localizedName : String?
    var path : String?
    var presenterName : String?
    var sourceMaterial : String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        localizedName  <- map["localizedName"]
        path  <- map["path"]
        presenterName  <- map["presenterName"]
        sourceMaterial  <- map["sourceMaterial"]
    }
    
}
