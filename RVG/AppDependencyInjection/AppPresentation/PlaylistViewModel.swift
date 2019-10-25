import Foundation
import RxSwift
import GRDB
import L10n_swift

protocol PlaylistViewModeling {
    func item(at indexPath: IndexPath) -> PlaylistItemType
}

private struct Constants {
    static let limit: Int = 100
}

final class PlaylistViewModel {
    public func section(at index: Int) -> PlaylistSectionViewModel {
        return sections.value[index]
    }
    
    public func item(at indexPath: IndexPath) -> PlaylistItemType {
        return section(at: indexPath.section).items[indexPath.item]
    }
    
    public private(set) var playlists = Field<[Playlist]>([])
    
    public private(set) var sections = Field<[PlaylistSectionViewModel]>([])
    public let selectItemEvent = PublishSubject<IndexPath>()
    
    public var fetchAppendPlaylists: PublishSubject = PublishSubject<Bool>()

    // true - the network fetch succeeded but yielded no results
    // false - the network fetch succeeded and yielded a result > 0
    public var emptyFetchResult: Field<Bool> = Field<Bool>(false)

    public var drillInEvent: Observable<PlaylistDrillInType> {
        // Emit events by mapping a tapped index path to setting-option.
        return self.selectItemEvent.filterMap { [unowned self] indexPath -> PlaylistDrillInType? in
            let section = self.sections.value[indexPath.section]
            let item = section.items[indexPath.item]
            // Don't emit an event for anything that is not a 'drillIn'
            if case .drillIn(let type, _, _, _) = item {
                return type
            }
            return nil
        }
    }
    
    public func fetchMorePlaylists() {
        // the case where are using playlists in cache/database
        // without fetching them from the network
        if self.totalEntries != -1 && self.totalEntries <= self.playlists.value.count {
            return
        }
        
        if self.totalEntries == self.playlists.value.count {
            return
        }
        
        switch self.networkStatus.value {
        case .notReachable:
            DDLogDebug("PlaylistViewModel reachability.notReachable")
            // possibly show an error to user
        case .reachable(_):
            
            // we can get playlists from server, so get them
            DDLogDebug("PlaylistViewModel reachability.reachable")
            self.fetchPlaylist(offset: lastOffset + 1,
                               limit: Constants.limit,
                               cacheDirective: .fetchAndAppend)
        case .unknown:
            DDLogDebug("PlaylistViewModel reachability.unknown")
            // possibly show an error to user
        }

    }
    
    // MARK: Dependencies
    
    private let channelUuid: String!
    private let productService: ProductServicing!
    private let languageService: LanguageServicing!
    private let reachability: RxClassicReachable!
    
    // MARK: Fields
    
    private var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)
    
    private var totalEntries: Int = -1
    private var totalPages: Int = -1
    private var pageSize: Int = -1
    private var pageNumber: Int = -1
    
    private var lastOffset: Int = 0

    private var bag = DisposeBag()
    
    internal init(channelUuid: String,
                  productService: ProductServicing,
                  languageService: LanguageServicing,
                  reachability: RxClassicReachable                  
        ) {
        self.channelUuid = channelUuid
        self.productService = productService
        self.languageService = languageService
        self.reachability = reachability
        setupDataSource()
    }
    
    func setupDataSource() {
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
        
        
        self.playlists.asObservable()
            .map { $0.map {
                var icon: String = "feetprint"
                switch $0.mediaCategory {
                case MediaCategory.bible.rawValue:
                    icon = "books-stack-of-three"
                case MediaCategory.gospel.rawValue:
                    icon = "creation"
                case MediaCategory.livestream.rawValue:
                    icon = "creation"
                case MediaCategory.motivation.rawValue:
                    icon = "creation"
                case MediaCategory.movie.rawValue:
                    icon = "creation"
                case MediaCategory.music.rawValue:
                    icon = "creation"
                case MediaCategory.podcast.rawValue:
                    icon = "creation"
                case MediaCategory.preaching.rawValue:
                    icon = "preaching"
                case MediaCategory.testimony.rawValue:
                    icon = "creation"
                case MediaCategory.tutorial.rawValue:
                    icon = "creation"
                case MediaCategory.conference.rawValue:
                    icon = "creation"
                default:
                    icon = "creation"
                }
                return PlaylistItemType.drillIn(type: .playlistItemType(item: $0, mediaCategory: $0.mediaCategory), iconName: icon, title: $0.localizedname, showBottomSeparator: true)
                }
            }
            .next { [unowned self] list in
                self.sections.value = [
                    PlaylistSectionViewModel(type: .playlist, items: list)
                ]
            }.disposed(by: self.bag)
        
        fetchAppendPlaylists.asObservable()
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .next { [unowned self] _ in
                self.fetchMorePlaylists()
            }.disposed(by: bag)
        
        languageService.swappedUserLanguage
            .asObservable()
            .subscribe(onNext: { [weak self] swappedLanguage in
                DDLogDebug("swappedLanguage user language: \(swappedLanguage) current language: \(L10n.shared.language) languageService user language: \(self?.languageService.userLanguage.value)")
                
                if let strongSelf = self {
                    if swappedLanguage != "none" {
                        strongSelf.productService.deletePlaylists(strongSelf.channelUuid)
                            .flatMap({ _ -> Single<Void> in
                                strongSelf.totalEntries = -1
                                strongSelf.totalPages = -1
                                strongSelf.pageSize = -1
                                strongSelf.pageNumber = -1
                                strongSelf.lastOffset = 0
                                
                                strongSelf.sections.value = []
                                strongSelf.fetchPlaylist(offset: strongSelf.lastOffset + 1,
                                                   limit: Constants.limit,
                                                   cacheDirective: .fetchAndReplace)
                                return Single.just(())
                            })
                            .asObservable()
                            .subscribeAndDispose(by: strongSelf.bag)
                    }
                }
            }, onError: { error in
                DDLogError("error: \(error)")
            })
            .disposed(by: bag)
    }
    
    func initialFetch() {
        productService.persistedPlaylists(for: self.channelUuid).subscribe(onSuccess: { [unowned self] playlists in
            if playlists.count == 0 {
                switch self.networkStatus.value {
                case .unknown, .notReachable:
                    DDLogError("⚠️ no playlists and no network! should probably make the user aware somehow")
                case .reachable(_):
                    self.fetchPlaylist(offset: self.lastOffset + 1,
                                       limit: Constants.limit,
                                       cacheDirective: .fetchAndAppend)
                }
            } else {
                self.playlists.value = playlists
                self.lastOffset = Int(ceil(CGFloat(playlists.count / Constants.limit)))
            }
        }) { error in
            DDLogDebug("error getting persistedPlaylists: \(error)")
            }.disposed(by: self.bag)
    }
    
    func fetchPlaylist(offset: Int, limit: Int, cacheDirective: CacheDirective) {
        DDLogDebug("fetchPlaylist self.channelUuid: \(self.channelUuid)")
        
        productService.fetchPlaylists(for: self.channelUuid, offset:  offset, limit: limit, cacheDirective: cacheDirective)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { (playlistResponse, playlists) in
                DDLogDebug("fetchPlaylists: \(playlists)")
                
                if cacheDirective == .fetchAndReplace {
                    self.playlists.value = playlists
                } else {
                    self.playlists.value.append(contentsOf: playlists)
                }
                self.totalEntries = playlistResponse.totalEntries
                self.totalPages = playlistResponse.totalPages
                self.pageSize = playlistResponse.pageSize
                self.pageNumber = playlistResponse.pageNumber
                
                self.lastOffset += 1
                
                self.emptyFetchResult.value = (playlists.count == 0)
                
            }) { error in
                
                if let dbError: DatabaseError = error as? DatabaseError {
                    switch dbError.extendedResultCode {
                    case .SQLITE_CONSTRAINT:            // any constraint error
                        DDLogDebug("SQLITE_CONSTRAINT error")
                        // it is possible that we already have some or all the playlists
                        // from a previous run and that the last fetch tried to
                        // insert values that were already present. So increment
                        // lastOffset by one so that eventually we will stop getting
                        // errors
                        //                    if self.playlists.value.count == limit && self.totalEntries == -1 {
                        //                        self.lastOffset += 1
                        //                    }
                        
                        // we got a SQLITE_CONSTRAINT error, assume that we at least have
                        // `limit` number of items
                        // this will stop the data service from continually calling the server
                        // because of the fetchMorePlaylists() guards
                        if self.playlists.value.count >= limit && self.totalEntries == -1 {
                            self.totalEntries = self.playlists.value.count
                        }
                    default:                            // any other database error
                        DDLogDebug("some db error: \(dbError)")
                    }
                    
                } else {
                    DDLogDebug("fetchPlaylists failed with error: \(error.localizedDescription)")
                }
                
                
        }.disposed(by: self.bag)
    }
    
    private func reactToReachability()  {
//        return Single.create { [unowned self] single -> Disposable in
            self.reachability.startNotifier().asObservable()
                .subscribe(onNext: { networkStatus in
                    self.networkStatus.value = networkStatus
                    switch networkStatus {
                    case .unknown:
                        DDLogDebug("PlaylistViewModel \(self.reachability.status.value)")
                    case .notReachable:
                        DDLogDebug("PlaylistViewModel \(self.reachability.status.value)")
                    case .reachable(_):
                        DDLogDebug("PlaylistViewModel \(self.reachability.status.value)")
                    }
                }).disposed(by: self.bag)
    }
}
