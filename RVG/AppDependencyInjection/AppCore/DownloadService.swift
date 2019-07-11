//
//  DownloadServicing.swift
//  FaithfulWord
//
//  Created by Michael on 2018-10-05.
//  Copyright © 2018 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift
import Moya

protocol DownloadServicing {
    //    var progress: Observable<Float> { get }
    //    var state: Observable<FileDownloadState> { get }
//    var fileDownload: Observable<FileDownload> { get }
    var downloadMap: [String: DownloadDataService] { get }
    func fetchDownload(url: String, filename: String) -> Single<Void>
//    func activeDownload(filename: String) -> Observable<FileDownload>
//    func cancelDownload(filename: String) -> Single<Void>
    func removeDownload(filename: String) -> Single<Void>
    func deleteDownloadService(filename: String) -> Single<Void>
}

public final class DownloadService: NSObject {
    
    // MARK: Fields(
    private let bag = DisposeBag()
    private var queue: OperationQueue {
        let queue: OperationQueue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }
    
    public var downloadMap: [String: DownloadDataService] = [:]
    
    
    //    public private(set) var media = Field<[Playable]>([])
    //    public var progress: Observable<Float> {
    //        return downloadDataService.progress
    //    }
    
//    public var fileDownload: Observable<FileDownload> {
//        return downloadDataService.fileDownload
//    }
    
    //    public var state: Observable<FileDownloadState> {
    //        return downloadDataService.state
    //    }
    
    // MARK: Dependencies
//    private let downloadDataService: FileDownloadDataServicing
//    
//    public init(downloadDataService: FileDownloadDataServicing) {
//        self.downloadDataService = downloadDataService
//    }
}

extension DownloadService: URLSessionDownloadDelegate {
//    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
//        DDLogDebug("urlSessionDidFinishEvents: \(session)")
//    }
//
//    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
//        DDLogDebug("didBecomeInvalidWithError: \(String(describing: error))")
//    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        DDLogDebug("didFinishDownloadingTo: session: \(String(describing: session)) downloadTask: \(downloadTask) location: \(location)")
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DDLogDebug("didFinishDownloadingTo: session: \(String(describing: session)) downloadTask: \(downloadTask) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        DDLogDebug("didFinishDownloadingTo: session: \(String(describing: session)) downloadTask: \(downloadTask) fileOffset: \(fileOffset) expectedTotalBytes: \(expectedTotalBytes)")
    }

}

extension DownloadService: DownloadServicing {
    func fetchDownload(url: String, filename: String) -> Single<Void> {
        DDLogDebug("fetchDownload")
        let configuration = URLSessionConfiguration.background(withIdentifier: "app.fwsaved.downloadsession")
        let sessionQueue = OperationQueue()
        let urlSession: URLSession = URLSession(configuration: configuration, delegate: self, delegateQueue: sessionQueue)

//        NSURL * url = [NSURL URLWithString:@"http://www.hdwallpapersinn.com/wp-content/uploads/2012/09/HD-Wallpaper-1920x1080.jpg"];
//        NSURLSessionConfiguration * backgroundConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:@"backgroundtask1"];
//
//        NSURLSession *backgroundSeesion = [NSURLSession sessionWithConfiguration: backgroundConfig delegate:self delegateQueue: [NSOperationQueue mainQueue]];
//
//        NSURLSessionDownloadTask * downloadTask =[ backgroundSeesion downloadTaskWithURL:url];
//        [downloadTask resume];
        if let remoteUrl = URL(string: url) {
            let task: URLSessionDownloadTask = urlSession.downloadTask(with: remoteUrl)
            task.resume()
        }
        
        //        if let remoteUrl: URL = URL(string: url) {
////            let operation = DownloadOperation(session: urlSession, downloadTaskURL: remoteUrl, completionHandler: { (localURL, response, error) in
////                print("finished downloading \(url) local: \(String(describing: localURL))")
////            })
//            let operation = DownloadOperation(session: urlSession, downloadTaskURL: remoteUrl, completionHandler: nil)
//
//            queue.addOperation(operation)
//        }
        
        return Single.just(())
        
        
//        let downloadDataService: DownloadDataService = DownloadDataService(fileWebService: MoyaProvider<FileWebService>())
//        downloadMap[filename] = downloadDataService
//        if let service = downloadMap[filename] {
//            return service.downloadFile(url: url, filename: filename)
//        } else { return Single.just(()) }
    }
    
//    func activeDownload(filename: String) -> Observable<FileDownload> {
//        var result: Observable<FileDownload>!
//        if let service = downloadMap[filename] {
//            result = service.fileDownload
//        } else {
//            result = Observable.error(FileDownloadError.missingDownload("no download for filename: \(filename)"))
//        }
//
//        return result
//    }
    
    // cancelDownload will cancel the download but will NOT remove
    // the partial file nor remove the downloadDataService from the map
//    func cancelDownload(filename: String) -> Single<Void> {
//        if let downloadDataService = downloadMap[filename] {
//            return downloadDataService.cancel()
//            //                .flatMap { self.removeDownload(filename: filename) }
//        } else {
//            return Single.error(FileDownloadError.missingDownload("download could not be cancelled"))
//        }
//    }
    
    // removeDownload will cancel the download, remove the partially downloaded
    // file and remove it from the downloadMap
    func removeDownload(filename: String) -> Single<Void> {
        if let downloadDataService = downloadMap[filename] {
            return downloadDataService.cancel()
                .flatMap { downloadDataService.deleteDownload() }
                .flatMap { self.deleteDownloadService(filename: filename) }
        } else {
            return Single.error(FileDownloadError.missingDownload("download could not be removed"))
        }
        //        if downloadMap[filename] != nil {
        //            downloadMap[filename] = nil
        //
        //            //            downloadDataService.deleteDownload
        //        } else {
        //            result = Single.error(FileDownloadError.missingDownload("download could not be removed"))
        //        }
        //        return result
    }
    
    func deleteDownloadService(filename: String) -> Single<Void> {
        return Single.create { [unowned self] single -> Disposable in
            if self.downloadMap[filename] != nil {
                self.downloadMap[filename] = nil
                single(.success(()))
            } else {
                single(.error(FileDownloadError.missingDownload("download could not be removed")))
            }
            return Disposables.create { }
        }
    }
}

