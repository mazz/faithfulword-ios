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
    func activeDownload(filename: String) -> Observable<FileDownload>
    func cancelDownload(filename: String) -> Single<Void>
    func removeDownload(filename: String) -> Single<Void>
    func deleteDownloadService(filename: String) -> Single<Void>
}

public final class DownloadService {
    
    // MARK: Fields(
    private let bag = DisposeBag()
    
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

extension DownloadService: DownloadServicing {
    func fetchDownload(url: String, filename: String) -> Single<Void> {
        DDLogDebug("fetchDownload")
        
        
        let downloadDataService: DownloadDataService = DownloadDataService(fileWebService: MoyaProvider<FileWebService>())
        downloadMap[filename] = downloadDataService
        if let service = downloadMap[filename] {
            return service.downloadFile(url: url, filename: filename)
        } else { return Single.just(()) }
    }
    
    func activeDownload(filename: String) -> Observable<FileDownload> {
        var result: Observable<FileDownload>!
        if let service = downloadMap[filename] {
            result = service.fileDownload
        } else {
            result = Observable.error(FileDownloadError.missingDownload("no download for filename: \(filename)"))
        }
        
        return result
    }
    
    // cancelDownload will cancel the download but will NOT remove
    // the partial file nor remove the downloadDataService from the map
    func cancelDownload(filename: String) -> Single<Void> {
        if let downloadDataService = downloadMap[filename] {
            return downloadDataService.cancel()
            //                .flatMap { self.removeDownload(filename: filename) }
        } else {
            return Single.error(FileDownloadError.missingDownload("download could not be cancelled"))
        }
    }
    
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

