//
//  NotificationService.swift
//  ImageServiceNotificationExtension
//
//  Created by Michael on 2019-12-11.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    var downloadTask: URLSessionDownloadTask?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            print("bestAttemptContent.userInfo: \(bestAttemptContent.userInfo)")
            
            if let title = bestAttemptContent.userInfo["title"] {
                bestAttemptContent.title = title as! String
            }
            
            var deeplink: String
            var image_thumbnail_path: String
            var media_item_uuid: String
            var org: String

            

            // Prioritize video over image
            if let imageURL = bestAttemptContent.userInfo["image_thumbnail_url"],
                let urlString = imageURL as? String {
                carnivalHandleAttachmentDownload(content: bestAttemptContent.userInfo, urlString: urlString)
            } else {
                // Nothing to add to the push, return early.
                contentHandler(bestAttemptContent)
                return
            }
            
            
        }
    }
    
    func carnivalHandleAttachmentDownload(content: [AnyHashable : Any], urlString: String) {
        
        guard let url = URL(string: urlString) else {
            // Cannot create a valid URL, return early.
            if let contentHandler = self.contentHandler,
                let bestAttemptContent = self.bestAttemptContent {
                contentHandler(bestAttemptContent)
            }
            return
        }
        
        self.downloadTask = URLSession.shared.downloadTask(with: url) { (location, response, error) in
            if let location = location {
                let tmpDirectory = NSTemporaryDirectory()
                let tmpFile = "file://".appending(tmpDirectory).appending(url.lastPathComponent)
                
                let tmpUrl = URL(string: tmpFile)!
                try! FileManager.default.moveItem(at: location, to: tmpUrl)
                
                if let attachment = try? UNNotificationAttachment(identifier: "", url: tmpUrl) {
                    self.bestAttemptContent?.attachments = [attachment]
                }
            }
            
            self.contentHandler!(self.bestAttemptContent!)
        }
        
        self.downloadTask?.resume()
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        self.downloadTask?.cancel()
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
