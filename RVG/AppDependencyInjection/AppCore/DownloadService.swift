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
    var operations: [String: DownloadOperation] { get }
    var fileDownloads: [String: FileDownload] { get }
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
    public var operations: [String: DownloadOperation] = [:]
    public var fileDownloads: [String: FileDownload] = [:]

    
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
        
        if let identifier: String = session.configuration.identifier,
            let finishingDownload: DownloadOperation = operations[identifier] {
            finishingDownload.cancel()
        }
        
//        DispatchQueue.main.async { [unowned self] in
            if let identifier: String = session.configuration.identifier,
                let fileDownload: FileDownload = self.fileDownloads[identifier] {
                
                var download = fileDownload
                download.state = .complete
                // refresh mapped download
                self.fileDownloads[identifier] = download
                
                NotificationCenter.default.post(name: DownloadDataService.fileDownloadDidCompleteNotification, object: download)
                
                let fullPath: URL = self.saveLocationUrl(identifier: identifier)
                DDLogDebug("fullPath: \(fullPath)")
                
                // capture the audio file as a Data blob and then write it
                // to temp dir
                
                do {
                    let audioData: Data = try Data(contentsOf: location, options: .uncached)
                    try audioData.write(to: fullPath, options: .atomicWrite)
                } catch {
                    DDLogDebug("error writing audio file: \(error)")
                    return
                }
                
                do {
                    // need to manually set 644 perms: https://github.com/Alamofire/Alamofire/issues/2527
                    try FileManager.default.setAttributes([FileAttributeKey.posixPermissions: NSNumber(value: 0o644)], ofItemAtPath: fullPath.path)
                } catch {
                    DDLogDebug("error while setting file permissions")
                }
            }
//        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DDLogDebug("didWriteData: session: \(String(describing: session)) downloadTask: \(downloadTask) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        DispatchQueue.main.async { [unowned self] in
            if let identifier: String = session.configuration.identifier,
                let fileDownload: FileDownload = self.fileDownloads[identifier] {
                var download = fileDownload
                download.completedCount = totalBytesWritten
                download.totalCount = totalBytesExpectedToWrite
                download.progress = Float(totalBytesWritten/totalBytesExpectedToWrite)
                download.state = .inProgress
                
                // refresh mapped download
                self.fileDownloads[identifier] = download
                
                NotificationCenter.default.post(name: DownloadDataService.fileDownloadDidProgressNotification, object: download)
            }
        }

    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        DDLogDebug("didResumeAtOffset: session: \(String(describing: session)) downloadTask: \(downloadTask) fileOffset: \(fileOffset) expectedTotalBytes: \(expectedTotalBytes)")
    }

}

extension DownloadService: DownloadServicing {
    func fetchDownload(url: String, filename: String) -> Single<Void> {
        DDLogDebug("fetchDownload")
        let identifier: String = "app.fwsaved.downloadsession_\(filename)"
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        let sessionQueue = OperationQueue()
        let urlSession: URLSession = URLSession(configuration: configuration, delegate: self, delegateQueue: sessionQueue)

        if let remoteUrl = URL(string: url) {
            let operation = DownloadOperation(session: urlSession, downloadTaskURL: remoteUrl)

            queue.addOperation(operation)
            operations[identifier] = operation
            
            let fileDownload: FileDownload = FileDownload(url: remoteUrl,
                                                          localUrl: saveLocationUrl(identifier: identifier),
                                                          progress: 0,
                                                          totalCount: 0,
                                                          completedCount: 0,
                                                          state: .initiating)
            fileDownloads[identifier] = fileDownload

            NotificationCenter.default.post(name: DownloadDataService.fileDownloadDidProgressNotification, object: fileDownload)

        }
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

extension DownloadService {
    func saveLocationUrl(identifier: String) -> URL {
        let components = identifier.split(separator:"_")
        let targetFilename: String = String(components[1])
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url: URL = urls[urls.endIndex - 1]
        
        let directory: URL = url.appendingPathComponent("Saved/")
        
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            DDLogDebug("error while creating directory")
        }
        
        let fullPath: URL = directory.appendingPathComponent(targetFilename)
        
        DDLogDebug("fullPath: \(fullPath)")
        
        return fullPath
        
        // capture the audio file as a Data blob and then write it
        // to temp dir
        
//        do {
//            let audioData: Data = try Data(contentsOf: location, options: .uncached)
//            try audioData.write(to: fullPath, options: .atomicWrite)
//        } catch {
//            DDLogDebug("error writing audio file: \(error)")
//            return
//        }
//
//        do {
//            // need to manually set 644 perms: https://github.com/Alamofire/Alamofire/issues/2527
//            try FileManager.default.setAttributes([FileAttributeKey.posixPermissions: NSNumber(value: 0o644)], ofItemAtPath: fullPath.path)
//        } catch {
//            DDLogDebug("error while setting file permissions")
//        }
    }
}

