
import Foundation

class Bible {
    static var bible :  Bible?
    
    public var books : [Book]?
    public var mediaChapter : [MediaChapter]?
    
    class func sharedInstance() -> Bible {
        DispatchQueue.once(token: "com.kjvrvg.dispatch.bible") {
            bible = Bible()
            
        }
        return bible!
    }
    
}
