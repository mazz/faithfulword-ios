//
//  DownloadListingViewModel.swift
//  FaithfulWord
//
//  Created by Michael on 2019-08-22.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

internal final class DownloadListingViewModel {
    // MARK: Fields
    
    // MARK: from client
    // the asset that the user intends to download
    //    public var downloadAsset = Field<Asset?>(nil)
    //<uuid>.mp3
//    public var downloadAssetIdentifier = Field<String?>(nil)
//    //https: //remoteurl.com/full/path.mp3
    public var fileDownloadDeleted = Field<String?>(nil)
//
//    // the state of the download button image name
//    public let downloadImageNameEvent = Field<String>("download_icon_black")
    // MARK: Dependencies
    private let downloadService: DownloadServicing!
    private let bag = DisposeBag()
    
    internal init(downloadService: DownloadServicing) {
        self.downloadService = downloadService
    }

    public func storedFileDownload(for playableUuid: String) -> Single<FileDownload?> {
        return self.downloadService.fetchFileDownloadHistory(playableUuid: playableUuid)
    }
    
    public func storedFileDownloads(for playableUuid: String) -> Single<[FileDownload]> {
        return self.downloadService.fetchStoredFileDownloads(for: playableUuid)
    }
    
    public func updateFileDownloadHistory(for fileDownload: FileDownload) {
        self.downloadService.updateFileDownloadHistory(fileDownload: fileDownload)
            .asObservable()
            .subscribeAndDispose(by: bag)
    }

    func deleteFileDownload(for playableUuid: String, pathExtension: String) {
        Observable.combineLatest(self.downloadService.deleteFileDownloadFile(playableUuid: playableUuid, pathExtension: pathExtension).asObservable(), self.downloadService.deleteFileDownloadHistory(playableUuid: playableUuid).asObservable())
            .next({ _ in
                DDLogDebug("deleteFileDownload deleted playableUuid: \(playableUuid)")
                self.fileDownloadDeleted.value = playableUuid
            })
            .disposed(by: bag)
    }
    
    func fetchDownload(for playable: Playable, playlistUuid: String) {
        if let path: String = playable.path,
            let remoteUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path)) {
            let fileIdentifier: String = playable.uuid.appending(String(describing: ".\(remoteUrl.pathExtension)"))
            
            downloadService.fetchDownload(url: remoteUrl.absoluteString,
                                          filename: fileIdentifier,
                                          playableUuid: playable.uuid,
                                          playlistUuid: playlistUuid)
        }
    }

    func cancelDownload(for playable: Playable, playlistUuid: String) {
        if let path: String = playable.path,
            let remoteUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path)) {
            let fileIdentifier: String = playable.uuid.appending(String(describing: ".\(remoteUrl.pathExtension)"))
            
            downloadService.cancelDownload(filename: fileIdentifier, playlistUuid: playlistUuid)
        }
    }
}

