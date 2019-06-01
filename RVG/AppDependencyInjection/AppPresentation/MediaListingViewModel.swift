import Foundation
import RxSwift

private struct Constants {
    static let limit: Int = 100
}

internal final class MediaListingViewModel {
    // MARK: Fields

    public func section(at index: Int) -> MediaListingSectionViewModel {
        return sections.value[index]
    }

    public func item(at indexPath: IndexPath) -> MediaListingItemType {
        return section(at: indexPath.section).items[indexPath.item]
    }

    public private(set) var media = Field<[Playable]>([])
    public private(set) var sections = Field<[MediaListingSectionViewModel]>([])
    public let selectItemEvent = PublishSubject<IndexPath>()

    public private(set) var playableItem = Field<Playable?>(nil)

    public var drillInEvent: Observable<MediaListingDrillInType> {
        // Emit events by mapping a tapped index path to setting-option.
        return self.selectItemEvent
            .do(onNext: { [weak self] indexPath in
                let section = self?.sections.value[indexPath.section]
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
                let section = self?.sections.value[indexPath.section]
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
        // the case where are using playlists in cache/database
        // without fetching them from the network
        if self.totalEntries != -1 && self.totalEntries <= self.media.value.count {
            return
        }
        
        switch self.networkStatus.value {
        case .notReachable:
            DDLogDebug("MediaListingViewModel reachability.notReachable")
        // possibly show an error to user
        case .reachable(_):
            
            // we can get playlists from server, so get them
            DDLogDebug("MediaListingViewModel reachability.reachable")
            self.fetchMedia(offset: self.lastOffset + 1,
                            limit: Constants.limit,
                            cacheRule: .fetchAndAppend)
        case .unknown:
            DDLogDebug("MediaListingViewModel reachability.unknown")
            // possibly show an error to user
        }
    }

    // MARK: Dependencies
    private let playlistUuid: String!
    private let mediaType: MediaType!
    private let productService: ProductServicing!
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

    internal init(playlistUuid: String,
                  mediaType: MediaType,
                  productService: ProductServicing,
                  assetPlaybackService: AssetPlaybackServicing,
                  reachability: RxClassicReachable)
//        assetPlaybackManager: AssetPlaybackManager,
//        remoteCommandManager: RemoteCommandManager)
    {
        self.playlistUuid = playlistUuid
        self.mediaType = mediaType
        self.productService = productService
        self.reachability = reachability
        self.assetPlaybackService = assetPlaybackService
        
//        self.assetPlaybackManager = assetPlaybackManager
//        self.remoteCommandManager = remoteCommandManager

        setupDatasource()
    }

    private func setupDatasource() {
        reactToReachability()
        
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

        self.media.asObservable()
            .map { $0.map {
                let icon: String!

                switch self.mediaType {
                case .audioChapter?:
                    icon = "chapter"
//                case .audioSermon?:
//                    icon = "feet"
                case .audioGospel?:
                    icon = "double_feetprint_icon_white"
                case .audioMusic?:
                    icon = "disc_icon_white"
                default:
                    icon = "feet"
                }
                
                var presenter: String = "Unknown Presenter"
                if let presenterName: String = $0.presenterName {
                    presenter = presenterName
                }
                
                return MediaListingItemType.drillIn(type: .playable(item: $0), iconName: icon, title: $0.localizedname, presenter: presenter, showBottomSeparator: true) }
            }
            .next { [unowned self] names in
                self.sections.value = [
                    MediaListingSectionViewModel(type: .media, items: names)
                ]
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
                    self.fetchMedia(offset: self.lastOffset + 1, limit: Constants.limit, cacheRule: .fetchAndAppend)
                }
            } else {
                self.media.value = persistedMediaItems
                self.lastOffset += 1
            }
        }) { error in
            DDLogDebug("error getting persistedMediaItems: \(error)")
            
            }.disposed(by: self.bag)
    }
    
    func fetchMedia(offset: Int, limit: Int, cacheRule: CacheRule) {
        productService.fetchMediaItems(for: playlistUuid, offset: offset, limit: limit, cacheRule: cacheRule).subscribe(onSuccess: { (mediaItemResponse, mediaItems) in
            DDLogDebug("fetchMediaItems: \(mediaItems)")
            self.media.value.append(contentsOf: mediaItems)
            self.totalEntries = mediaItemResponse.totalEntries
            self.totalPages = mediaItemResponse.totalPages
            self.pageSize = mediaItemResponse.pageSize
            self.pageNumber = mediaItemResponse.pageNumber
            
            self.lastOffset += 1
        }) { error in
            DDLogDebug("fetchMediaItems failed with error: \(error.localizedDescription)")
            }.disposed(by: self.bag)
    }
    
    private func reactToReachability() {
        self.reachability.startNotifier().asObservable()
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
