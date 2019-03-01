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
    var fileDownload: Observable<FileDownload> { get }
    var downloadMap: [String: DownloadDataService] { get }
    func fetchDownload(url: String, filename: String) -> Single<Void>
    func activeDownload(filename: String) -> Observable<FileDownload>
    func cancelDownload(filename: String) -> Single<Void>
    func removeDownload(filename: String) -> Single<Void>
}

public final class DownloadService {

    // MARK: Fields(
    private let bag = DisposeBag()

    public var downloadMap: [String: DownloadDataService] = [:]

//    public private(set) var media = Field<[Playable]>([])
//    public var progress: Observable<Float> {
//        return downloadDataService.progress
//    }

    public var fileDownload: Observable<FileDownload> {
        return downloadDataService.fileDownload
    }

//    public var state: Observable<FileDownloadState> {
//        return downloadDataService.state
//    }

    // MARK: Dependencies
    private let downloadDataService: FileDownloadDataServicing

    public init(downloadDataService: FileDownloadDataServicing) {
        self.downloadDataService = downloadDataService
    }
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

    func cancelDownload(filename: String) -> Single<Void> {
        var result: Single<Void> = Single.just(())

        if let service = downloadMap[filename] {
            service.cancel()

            // seems reasonable that cancelled downloads are removed
            result = removeDownload(filename: filename)
        } else {
            result = Single.error(FileDownloadError.missingDownload("download could not be cancelled"))
        }
        return result
    }

    func removeDownload(filename: String) -> Single<Void> {
        var result: Single<Void> = Single.just(())

        if downloadMap[filename] != nil {
            downloadMap[filename] = nil
        } else {
            result = Single.error(FileDownloadError.missingDownload("download could not be removed"))
        }
        return result
    }
}
