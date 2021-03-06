import Foundation
import RxSwift
import GRDB

private struct Constants {
    static let limit: Int = 100
}

internal final class MediaListingViewModel {
    // MARK: Fields

    public func section(at index: Int) -> MediaListingSectionViewModel {
        return filteredSections.value[index]
    }

    public func item(at indexPath: IndexPath) -> MediaListingItemType {
        return section(at: indexPath.section).items[indexPath.item]
    }

    public var filterText: PublishSubject<String> = PublishSubject<String>()
    public var filterTextObservable: Observable<String> {
        return filterText.asObservable()
    }
    
    // onNext will append a fetched search to the current results with the
    // current searchText
    public var fetchAppendMedia: PublishSubject<Bool> = PublishSubject<Bool>()
    
    // true - the search for the current filterText yields no results
    // false - the search for the current filterText yields a result > 0
    public var emptyFilteredResult: Field<Bool> = Field<Bool>(false)

    // true - the network fetch succeeded but yielded no results
    // false - the network fetch succeeded and yielded a result > 0
    public var emptyFetchResult: Field<Bool> = Field<Bool>(false)

    // media loaded on initial fetch
    public private(set) var media = Field<[Playable]>([])
    public private(set) var sections = Field<[MediaListingSectionViewModel]>([])
    // media filtered by filterText
    public private(set) var filteredMedia = Field<[Playable]>([])
    public private(set) var filteredSections = Field<[MediaListingSectionViewModel]>([])

    public let selectItemEvent = PublishSubject<IndexPath>()

    public private(set) var playableItem = Field<Playable?>(nil)

    public var drillInEvent: Observable<MediaListingDrillInType> {
        // Emit events by mapping a tapped index path to setting-option.
        return self.selectItemEvent
            .do(onNext: { [weak self] indexPath in
                let section = self?.filteredSections.value[indexPath.section]
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
                let section = self?.filteredSections.value[indexPath.section]
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
            DDLogDebug("MediaListingViewModel reachability.notReachable")
        // do nothing because we can't fetch
        case .reachable(_):
            
            // we can get media from server, so get them
            DDLogDebug("MediaListingViewModel reachability.reachable")
            self.fetchMedia(offset: self.lastOffset + 1,
                            limit: Constants.limit,
                            cacheDirective: .fetchAndAppend)
        case .unknown:
            DDLogDebug("MediaListingViewModel reachability.unknown")
            // do nothing because we can't fetch
        }
    }

    // MARK: Dependencies
    public let playlistUuid: String!
    public var mediaCategory: MediaCategory!
    public private(set) var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)
    
    private let productService: ProductServicing!
    private let assetPlaybackService: AssetPlaybackServicing!
    private let reachability: RxClassicReachable!

    // MARK: Fields
    
    
    private var totalEntries: Int = -1
    private var totalPages: Int = -1
    private var pageSize: Int = -1
    private var pageNumber: Int = -1
    
    private var lastOffset: Int = 0

    private let bag = DisposeBag()

    internal init(playlistUuid: String,
                  mediaCategory: MediaCategory,
                  productService: ProductServicing,
                  assetPlaybackService: AssetPlaybackServicing,
                  reachability: RxClassicReachable)
    {
        self.playlistUuid = playlistUuid
        self.mediaCategory = mediaCategory
        self.productService = productService
        self.reachability = reachability
        self.assetPlaybackService = assetPlaybackService

        setupDatasource()
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
                self.initialFetch()
        }.disposed(by: self.bag)


        // setup media sections
        self.media.asObservable()
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
                var presenter: String = NSLocalizedString("Unknown Presenter", comment: "").l10n()
                if let presenterName: String = $0.presenter_name {
                    presenter = presenterName
                }
                
                return MediaListingItemType.drillIn(type: .playable(item: $0), iconName: icon, title: $0.localizedname, presenter: presenter, showBottomSeparator: true) }
            }
            .next { [unowned self] names in
                self.sections.value = [
                    MediaListingSectionViewModel(type: .media, items: names)
                ]
            }.disposed(by: bag)

        // setup filteredMedia sections
        self.filteredMedia.asObservable()
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
                var presenter: String = NSLocalizedString("Unknown Presenter", comment: "").l10n()
                if let presenterName: String = $0.presenter_name {
                    presenter = presenterName
                }
                
                return MediaListingItemType.drillIn(type: .playable(item: $0), iconName: icon, title: $0.localizedname, presenter: presenter, showBottomSeparator: true) }
            }
            .next { [unowned self] names in
                self.filteredSections.value = [
                    MediaListingSectionViewModel(type: .media, items: names)
                ]
            }.disposed(by: bag)

        
        fetchAppendMedia.asObservable()
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .next { [unowned self] _ in
                self.fetchMoreMedia()
            }.disposed(by: bag)

        filterTextObservable
            .next { filterText in
                DDLogDebug("filterText: \(filterText)")
                
                self.media.asObservable()
                    .map({ $0.filter({
                        if filterText.isEmpty { return true }
                        return ($0.localizedname.lowercased().contains(filterText.lowercased()))
                    })
                    }).subscribe(onNext: { filteredPlayables in
                        
                        switch self.networkStatus.value {
                            
                        case .unknown:
                            DDLogDebug("filteredPlayables count: \(filteredPlayables.count)")
                            self.emptyFilteredResult.value = (filteredPlayables.count == 0)
                            self.filteredMedia.value = filteredPlayables
                        case .notReachable:
                            DDLogDebug("filteredPlayables count: \(filteredPlayables.count)")
                            self.emptyFilteredResult.value = (filteredPlayables.count == 0)
                            self.filteredMedia.value = filteredPlayables
                        case .reachable(_):
                            DDLogDebug("do nothing with \(filterText) because we are online")
                        }
                    }).disposed(by: self.bag)
        }.disposed(by: bag)
    }
    
    func initialFetch() {
        productService.persistedMediaItems(for: self.playlistUuid).subscribe(onSuccess: { [unowned self] persistedMediaItems in
            if persistedMediaItems.count == 0 {
                switch self.networkStatus.value {
                case .unknown:
                    DDLogError("⚠️ no persistedMediaItems and no network! should probably make the user aware somehow")
                case .notReachable:
                    DDLogError("⚠️ no persistedMediaItems and no network! should probably make the user aware somehow")
                case .reachable(_):
                    self.fetchMedia(offset: self.lastOffset + 1, limit: Constants.limit, cacheDirective: .fetchAndAppend)
                }
            } else {
                self.media.value = persistedMediaItems
                self.assetPlaybackService.playables.value = self.media.value
                
                // self.media is our source of truth
                self.filteredMedia.value = self.media.value
                
                self.emptyFetchResult.value = (persistedMediaItems.count == 0)

                
                self.lastOffset = Int(ceil(CGFloat(persistedMediaItems.count / Constants.limit)))
            }
        }) { error in
            DDLogDebug("error getting persistedMediaItems: \(error)")
            
            }.disposed(by: self.bag)
    }
    
    func fetchMedia(offset: Int, limit: Int, cacheDirective: CacheDirective) {
        productService.fetchMediaItems(for: playlistUuid, offset: offset, limit: limit, cacheDirective: cacheDirective).subscribe(onSuccess: { (mediaItemResponse, mediaItems) in
//            DDLogDebug("fetchMediaItems: \(mediaItems)")
            self.media.value.append(contentsOf: mediaItems)
            
            self.filteredMedia.value = self.media.value
            
            self.totalEntries = mediaItemResponse.total_entries
            self.totalPages = mediaItemResponse.total_pages
            self.pageSize = mediaItemResponse.page_size
            self.pageNumber = mediaItemResponse.page_number
            if let mediaCategoryString = mediaItems.first?.media_category {
                self.mediaCategory = MediaCategory(rawValue: mediaCategoryString)
            }
            
            self.lastOffset += 1
            
            self.assetPlaybackService.playables.value = self.media.value
            
            self.emptyFetchResult.value = (mediaItems.count == 0)

        }) { error in
            
            if let dbError: DatabaseError = error as? DatabaseError {
                switch dbError.extendedResultCode {
                case .SQLITE_CONSTRAINT:            // any constraint error
                    DDLogDebug("SQLITE_CONSTRAINT error")
                    // it is possible that we already have some or all the media
                    // from a previous run and that the last fetch tried to
                    // insert values that were already present. So increment
                    // lastOffset by one so that eventually we will stop getting
                    // errors
//                    if self.media.value.count == limit && self.totalEntries == -1 {
//                        self.lastOffset += 1
//                    }
                    
                    // we got a SQLITE_CONSTRAINT error, assume that we at least have
                    // `limit` number of items
                    // this will stop the data service from continually calling the server
                    // because of the fetchMoreMedia() guards
                    if self.media.value.count >= limit && self.totalEntries == -1 {
                        self.totalEntries = self.media.value.count

                    }
                default:                            // any other database error
                    DDLogDebug("some db error: \(dbError)")
                }
                
            } else {
                DDLogDebug("fetchMedia failed with error: \(error.localizedDescription)")
            }
            
            
            }.disposed(by: self.bag)
    }
    
    private func reactToReachability() {
        self.reachability.startNotifier().asObservable()
//            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { networkStatus in
                self.networkStatus.value = networkStatus
                switch networkStatus {
                case .unknown:
                    DDLogDebug("MediaListingViewModel \(self.reachability.status.value)")
                case .notReachable:
                    DDLogDebug("MediaListingViewModel \(self.reachability.status.value)")
                case .reachable(_):
                    DDLogDebug("MediaListingViewModel \(self.reachability.status.value)")
                }
            }).disposed(by: self.bag)
    }
}
