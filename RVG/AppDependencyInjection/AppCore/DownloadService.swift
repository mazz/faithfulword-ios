//
//  DownloadServicing.swift
//  FaithfulWord
//
//  Created by Michael on 2018-10-05.
//  Copyright © 2018 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

protocol DownloadServicing {
//    var progress: Observable<Float> { get }
    var state: Observable<FileDownloadState> { get }
    var fileDownload: Observable<FileDownload> { get }
    func fetchDownload(url: String, filename: String) -> Single<Void>
}

public final class DownloadService {

    // MARK: Fields(
    private let bag = DisposeBag()

//    private let downloadMap: [String: Observable<FileDownload>] = [:]

//    public private(set) var media = Field<[Playable]>([])
//    public var progress: Observable<Float> {
//        return downloadDataService.progress
//    }

    public var fileDownload: Observable<FileDownload> {
        return downloadDataService.fileDownload
    }

    public var state: Observable<FileDownloadState> {
        return downloadDataService.state
    }

    // MARK: Dependencies
    private let downloadDataService: FileDownloadDataServicing

    public init(downloadDataService: FileDownloadDataServicing) {
        self.downloadDataService = downloadDataService
    }
}

extension DownloadService: DownloadServicing {

    func fetchDownload(url: String, filename: String) -> Single<Void> {
        print("fetchDownload")
        return downloadDataService.downloadFile(url: url, filename: filename)
    }

}
