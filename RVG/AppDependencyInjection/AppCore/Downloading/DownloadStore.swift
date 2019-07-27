//
//  DownloadStore.swift
//  FaithfulWord
//
//  Created by Michael on 2019-07-25.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation


class DownloadStore: NSObject, HWIFileDownloadDelegate {
    
    // HWIFileDownloadDelegate (mandatory)
    
    @objc public func downloadDidComplete(withIdentifier identifier: String, localFileURL: URL) {
        print("yes")
    }
    
    @objc public func downloadFailed(withIdentifier identifier: String, error: Error, httpStatusCode: Int, errorMessagesStack: [String]?, resumeData: Data?) {
        print("no")
    }
    
    @objc public func incrementNetworkActivityIndicatorActivityCount() {
        //
    }
    
    @objc public func decrementNetworkActivityIndicatorActivityCount() {
        //
    }
    
    // HWIFileDownloadDelegate (optional)
    /*
     @objc public func downloadProgressChanged(forIdentifier identifier: String) {
     //
     }
     
     @objc public func downloadPaused(withIdentifier identifier: String, resumeData: Data?) {
     //
     }
     
     @objc public func resumeDownload(withIdentifier identifier: String) {
     //
     }
     
     @objc public func localFileURL(forIdentifier identifier: String, remoteURL: URL) -> URL? {
     return nil
     }
     
     @objc public func download(atLocalFileURL localFileURL: URL, isValidForDownloadIdentifier downloadIdentifier: String) -> Bool {
     return true
     }
     
     @objc public func httpStatusCode(_ httpStatusCode: Int, isValidForDownloadIdentifier downloadIdentifier: String) -> Bool {
     return true
     }
     
     @objc public func customizeBackgroundSessionConfiguration(_ backgroundSessionConfiguration: URLSessionConfiguration) {
     //
     }
     
     @objc public func urlRequest(forRemoteURL remoteURL: URL) -> URLRequest? {
     return nil
     }
     
     @objc public func onAuthenticationChallenge(_ challenge: URLAuthenticationChallenge, downloadIdentifier: String, completionHandler: @escaping (URLCredential?, URLSession.AuthChallengeDisposition) -> Void) {
     //
     }
     
     @objc public func rootProgress() -> Progress? {
     return nil
     }
     */
}
