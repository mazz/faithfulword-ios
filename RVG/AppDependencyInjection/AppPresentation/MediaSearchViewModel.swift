//
//  MediaSearchViewModel.swift
//  FaithfulWord
//
//  Created by Michael on 2019-08-31.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift
import GRDB

private struct Constants {
    static let limit: Int = 10000000
}

internal final class MediaSearchViewModel {
    // MARK: Fields
    
    public func section(at index: Int) -> MediaListingSectionViewModel {
        return sections.value[index]
    }
    
    public func item(at indexPath: IndexPath) -> MediaListingItemType {
        return section(at: indexPath.section).items[indexPath.item]
    }
    
    public var filterText: PublishSubject<String> = PublishSubject<String>()
    public var filterTextObservable: Observable<String> {
        return filterText.asObservable()
    }
    
    public var searchText: Field<String> = Field<String>("")
    
    //    public var searchValue: Field<String> = Field<String>("")
    //    var searchValueObservable: Observable<String> {
    //        return searchValue.asObservable()
    //    }
    
    // media filtered by search bar
    
    // media loaded on search fetch
    public private(set) var searchedMedia = Field<[Playable]>([])
    public private(set) var searchedSections = Field<[MediaListingSectionViewModel]>([])
    
    // media loaded on initial fetch
    public private(set) var media = Field<[Playable]>([])
    public private(set) var sections = Field<[MediaListingSectionViewModel]>([])
    public let selectItemEvent = PublishSubject<IndexPath>()
    
    public private(set) var playableItem = Field<Playable?>(nil)
    
    public var drillInEvent: Observable<MediaListingDrillInType> {
        // Emit events by mapping a tapped index path to setting-option.
        return self.selectItemEvent
            .do(onNext: { [weak self] indexPath in
                let section = self?.searchedSections.value[indexPath.section]
                let item = section?.items[indexPath.item]
                DDLogDebug("item: \(String(describing: item))")
                if case .drillIn(let type, _, _, _, _)? = item {
                    switch type {
                    case .playable(let item):
                        DDLogDebug("item: \(item)")
                        self?.assetPlaybackService.playableItem.value = item
                    }
                }
                
            })
            .filterMap { [weak self] indexPath -> MediaListingDrillInType? in
                let section = self?.searchedSections.value[indexPath.section]
                let item = section?.items[indexPath.item]
                // Don't emit an event for anything that is not a 'drillIn'
                if case .drillIn(let type, _, _, _, _)? = item {
                    return type
                }
                return nil
        }
    }
    
    public func fetchMoreMedia() {
        DDLogDebug("fetchMoreMedia")
        // the case where are using media in cache/database
        // without fetching them from the network
        if self.totalEntries != -1 && self.totalEntries <= self.media.value.count {
            return
        }
        
        if self.totalEntries == self.media.value.count {
            return
        }
        
        switch self.networkStatus.value {
        case .notReachable:
            DDLogDebug("MediaSearchViewModel reachability.notReachable")
        // do nothing because we can't fetch
        case .reachable(_):
            
            // we can get media from server, so get them
            DDLogDebug("MediaSearchViewModel reachability.reachable")
            self.fetchMedia(offset: self.lastOffset + 1,
                            limit: Constants.limit,
                            cacheDirective: .fetchAndAppend)
        case .unknown:
            DDLogDebug("MediaSearchViewModel reachability.unknown")
            // do nothing because we can't fetch
        }
    }
    
    // MARK: Dependencies
    public let playlistUuid: String!
    private let mediaCategory: MediaCategory!
//    private let productService: ProductServicing!
    private let searchService: SearchServicing!
    private let assetPlaybackService: AssetPlaybackServicing!
    private let reachability: RxClassicReachable!
    
    //    private let assetPlaybackManager: AssetPlaybackManager!
    //    private let remoteCommandManager: RemoteCommandManager!
    // MARK: Fields
    
    private var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)
    
    private var totalEntries: Int = -1
    private var totalPages: Int = -1
    private var pageSize: Int = -1
    private var pageNumber: Int = -1
    
    private var lastOffset: Int = 0
    
    private let bag = DisposeBag()
    
    internal init(
        playlistUuid: String,
                  mediaCategory: MediaCategory,
//                  productService: ProductServicing,
                  searchService: SearchServicing,
                  assetPlaybackService: AssetPlaybackServicing,
                  reachability: RxClassicReachable)
        //        assetPlaybackManager: AssetPlaybackManager,
        //        remoteCommandManager: RemoteCommandManager)
    {
        self.playlistUuid = playlistUuid
        self.mediaCategory = mediaCategory
//        self.mediaType = mediaType
//        self.productService = productService
        self.searchService = searchService
        self.reachability = reachability
        self.assetPlaybackService = assetPlaybackService
        
        //        self.assetPlaybackManager = assetPlaybackManager
        //        self.remoteCommandManager = remoteCommandManager
        
        setupDatasource()
        
        // detect when user does a search and taps the search button
        searchText.asObservable()
            .filter({ $0.count > 0 })
            .subscribe(onNext: { [unowned self] searchText in
                DDLogDebug("searchText: \(searchText)")
                self.searchService.searchMediaItems(query: searchText,
                                                    mediaCategory: self.mediaCategory.map { $0.rawValue },
                                                    playlistUuid: self.playlistUuid,
                                                    channelUuid: nil,
                                                    publishedAfter: nil,
                                                    updatedAfter: nil,
                                                    presentedAfter: nil,
                                                    offset: 1,
                                                    limit: Constants.limit,
                                                    cacheDirective: .fetchAndAppend)
                    .subscribe(onSuccess: { mediaItemResponse, mediaItems in
                        DDLogDebug("search media items: \(mediaItems)")
                        self.searchedMedia.value = mediaItems
                    }, onError: { error in
                        DDLogError("search media items error: \(error)")
                    })
                    .disposed(by: self.bag)
            })
            .disposed(by: bag)
    }
    
    private func setupDatasource() {
        reactToReachability()
        
        // do fetch when network reachability is detected
        networkStatus.asObservable()
            //            .observeOn(MainScheduler.instance)
            .map({ status -> String in
                
                var outStatus: String = "unknown"
                switch status {
                    
                case .unknown:
                    outStatus = "unknown"
                case .notReachable:
                    outStatus = "notReachable"
                case .reachable(_):
                    outStatus = "reachable"
                }
                return outStatus
            })
            .filter { $0 == "reachable" || $0 == "notReachable"}
            .take(1)
            .next { [unowned self] status in
                DDLogDebug("take status: \(status)")
//                self.initialFetch()
            }.disposed(by: self.bag)
        
        // setup searchedMedia sections
        self.searchedMedia.asObservable()
            .map { $0.map {
                let icon: String!
                
                switch self.mediaCategory {
                case .none:
                    icon = "chapter"
                case .some(.gospel):
                    icon = "feet"
                case .some(.livestream):
                    icon = "disc_icon_white"
                case .some(.motivation):
                    icon = "feet"
                case .some(.movie):
                    icon = "disc_icon_white"
                case .some(.music):
                    icon = "disc_icon_white"
                case .some(.podcast):
                    icon = "disc_icon_white"
                case .some(.preaching):
                    icon = "feet"
                case .some(.testimony):
                    icon = "feet"
                case .some(.tutorial):
                    icon = "feet"
                case .some(.conference):
                    icon = "disc_icon_white"
                case .some(.bible):
                    icon = "chapter"
                }
//                switch self.mediaType {
//                case .audioChapter?:
//                    icon = "chapter"
//                    //                case .audioSermon?:
//                //                    icon = "feet"
//                case .audioGospel?:
//                    icon = "double_feetprint_icon_white"
//                case .audioMusic?:
//                    icon = "disc_icon_white"
//                default:
//                    icon = "feet"
//                }
                
                var presenter: String = "Unknown Presenter"
                if let presenterName: String = $0.presenterName {
                    presenter = presenterName
                }
                
                return MediaListingItemType.drillIn(type: .playable(item: $0), iconName: icon, title: $0.localizedname, presenter: presenter, showBottomSeparator: true) }
            }
            .next { [unowned self] names in
                self.searchedSections.value = [
                    MediaListingSectionViewModel(type: .media, items: names)
                ]
            }.disposed(by: bag)
        
        // setup media sections
//        self.media.asObservable()
//            .map { $0.map {
//                let icon: String!
//
//                switch self.mediaType {
//                case .audioChapter?:
//                    icon = "chapter"
//                    //                case .audioSermon?:
//                //                    icon = "feet"
//                case .audioGospel?:
//                    icon = "double_feetprint_icon_white"
//                case .audioMusic?:
//                    icon = "disc_icon_white"
//                default:
//                    icon = "feet"
//                }
//
//                var presenter: String = "Unknown Presenter"
//                if let presenterName: String = $0.presenterName {
//                    presenter = presenterName
//                }
//
//                return MediaListingItemType.drillIn(type: .playable(item: $0), iconName: icon, title: $0.localizedname, presenter: presenter, showBottomSeparator: true, showAmountDownloaded: false) }
//            }
//            .next { [unowned self] names in
//                self.sections.value = [
//                    MediaListingSectionViewModel(type: .media, items: names)
//                ]
//            }.disposed(by: bag)

    }
    
    func initialFetch() {
//        productService.persistedMediaItems(for: self.playlistUuid).subscribe(onSuccess: { [unowned self] persistedMediaItems in
//            if persistedMediaItems.count == 0 {
//                switch self.networkStatus.value {
//                case .unknown:
//                    DDLogError("⚠️ no persistedMediaItems and no network! should probably make the user aware somehow")
//                case .notReachable:
//                    DDLogError("⚠️ no persistedMediaItems and no network! should probably make the user aware somehow")
//                case .reachable(_):
//                    self.fetchMedia(offset: self.lastOffset + 1, limit: Constants.limit, cacheDirective: .fetchAndAppend)
//                }
//            } else {
//                self.media.value = persistedMediaItems
//                self.assetPlaybackService.playables.value = self.media.value
//                self.lastOffset = Int(ceil(CGFloat(persistedMediaItems.count / Constants.limit)))
//            }
//        }) { error in
//            DDLogDebug("error getting persistedMediaItems: \(error)")
//
//            }.disposed(by: self.bag)
    }
    
    func fetchMedia(offset: Int, limit: Int, cacheDirective: CacheDirective) {
//        productService.fetchMediaItems(for: playlistUuid, offset: offset, limit: limit, cacheDirective: cacheDirective).subscribe(onSuccess: { (mediaItemResponse, mediaItems) in
//            DDLogDebug("fetchMediaItems: \(mediaItems)")
//            self.media.value.append(contentsOf: mediaItems)
//            self.totalEntries = mediaItemResponse.totalEntries
//            self.totalPages = mediaItemResponse.totalPages
//            self.pageSize = mediaItemResponse.pageSize
//            self.pageNumber = mediaItemResponse.pageNumber
//
//            self.lastOffset += 1
//
//            self.assetPlaybackService.playables.value = self.media.value
//        }) { error in
//
//            if let dbError: DatabaseError = error as? DatabaseError {
//                switch dbError.extendedResultCode {
//                case .SQLITE_CONSTRAINT:            // any constraint error
//                    DDLogDebug("SQLITE_CONSTRAINT error")
//                    // it is possible that we already have some or all the media
//                    // from a previous run and that the last fetch tried to
//                    // insert values that were already present. So increment
//                    // lastOffset by one so that eventually we will stop getting
//                    // errors
//                    //                    if self.media.value.count == limit && self.totalEntries == -1 {
//                    //                        self.lastOffset += 1
//                    //                    }
//
//                    // we got a SQLITE_CONSTRAINT error, assume that we at least have
//                    // `limit` number of items
//                    // this will stop the data service from continually calling the server
//                    // because of the fetchMoreMedia() guards
//                    if self.media.value.count >= limit && self.totalEntries == -1 {
//                        self.totalEntries = self.media.value.count
//                    }
//                default:                            // any other database error
//                    DDLogDebug("some db error: \(dbError)")
//                }
//
//            } else {
//                DDLogDebug("fetchMedia failed with error: \(error.localizedDescription)")
//            }
//
//
//            }.disposed(by: self.bag)
    }
    
    private func reactToReachability() {
        self.reachability.startNotifier().asObservable()
            .subscribe(onNext: { networkStatus in
                self.networkStatus.value = networkStatus
                switch networkStatus {
                case .unknown:
                    DDLogDebug("MediaSearchViewModel \(self.reachability.status.value)")
                case .notReachable:
                    DDLogDebug("MediaSearchViewModel \(self.reachability.status.value)")
                case .reachable(_):
                    DDLogDebug("MediaSearchViewModel \(self.reachability.status.value)")
                }
            }).disposed(by: self.bag)
    }
}

