//
//  UIViewController+Sharing.swift
//  FaithfulWord
//
//  Created by Michael on 2019-09-21.
//  Copyright © 2019 KJVRVG. All rights reserved.
//


import UIKit

public extension UIViewController {

    func shareLink(mediaItem: MediaItem) {
        if let hashLink: URL = URL(string: "https://api.faithfulword.app/m"),
            let presenterName: String = mediaItem.presenterName ?? "Unknown Presenter",
            let shareUrl: URL = hashLink.appendingPathComponent(mediaItem.hashId) {
            DDLogDebug("hashLink: \(shareUrl)")
            
            let message = MessageWithSubjectActivityItem(subject: String(describing: "\(mediaItem.localizedname) by \(presenterName)"), message: "Shared via the Faithful Word App: https://faithfulwordapp.com/")
            let itemsToShare: [Any] = [message, shareUrl]
            
            let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
            
            activityViewController.excludedActivityTypes = [
                .addToReadingList,
                .openInIBooks,
                .print,
                .saveToCameraRoll,
                .postToWeibo,
                .postToFlickr,
                .postToVimeo,
                .postToTencentWeibo]
            
            self.present(activityViewController, animated: true, completion: {})
        }
        
        
    }
    
    func shareFile(mediaItem: MediaItem) {
        // copy file to temp dir to rename it
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        // generate temp file url path
        
        if let presenterName: String = mediaItem.presenterName ?? "Unknown Presenter",
            let path: String = mediaItem.path,
            let percentEncoded: String = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let remoteUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(percentEncoded)) {
            
            let firstPart: String = "\(presenterName.replacingOccurrences(of: " ", with: ""))"
            let secondPart: String = "\(mediaItem.localizedname.replacingOccurrences(of: " ", with: "")).\(remoteUrl.pathExtension)"
            let destinationLastPathComponent: String = String(describing: "\(firstPart)-\(secondPart)")
            
            let sourceFileUrl: URL = FileSystem.savedDirectory.appendingPathComponent(mediaItem.uuid.appending(String(describing: ".\(remoteUrl.pathExtension)")))
            let temporaryFileURL: URL = temporaryDirectoryURL.appendingPathComponent(destinationLastPathComponent)
            DDLogDebug("temporaryFileURL: \(temporaryFileURL)")
            
            // capture the audio file as a Data blob and then write it
            // to temp dir
            
            do {
                let audioData: Data = try Data(contentsOf: sourceFileUrl, options: .uncached)
                try audioData.write(to: temporaryFileURL, options: .atomicWrite)
            } catch {
                DDLogDebug("error writing temp audio file: \(error)")
                return
            }
            
            let message = MessageWithSubjectActivityItem(subject: String(describing: "\(mediaItem.localizedname) by \(presenterName)"), message: "Shared via the Faithful Word App: https://faithfulwordapp.com/")
            let itemsToShare: [Any] = [message, temporaryFileURL]
            
            let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
            
            activityViewController.excludedActivityTypes = [
                .addToReadingList,
                .openInIBooks,
                .print,
                .saveToCameraRoll,
                .postToWeibo,
                .postToFlickr,
                .postToVimeo,
                .postToTencentWeibo]
            
            self.present(activityViewController, animated: true, completion: {})
        }        
    }
}
