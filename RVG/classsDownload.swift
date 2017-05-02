import Foundation

class Download: NSObject {
    
    var url: String
    var isDownloading = false
    var progress: Float = 0.0
    
    var downloadTask: URLSessionDownloadTask?
    var resumeData: NSData?
    
    init(url: String) {
        self.url = url
    }
}
