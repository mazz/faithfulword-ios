import Foundation
import RxSwift

private struct Constants {
    static let limit: Int = 50
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
        if self.totalEntries <= self.playlists.value.count {
            return
        }
        
        switch self.networkStatus.value {
        case .notReachable:
            DDLogDebug("PlaylistViewModel reachability.notReachable")
            // do nothing for now
        case .reachable(_):
            DDLogDebug("PlaylistViewModel reachability.reachable")
            self.fetchPlaylist(offset: lastOffset + 1,
                               limit: Constants.limit,
                               cacheRule: .fetchAndAppend)
        case .unknown:
            DDLogDebug("PlaylistViewModel reachability.unknown")
            // do nothing for now
        }

    }
    
    // MARK: Dependencies
    
    private let channelUuid: String!
    private let productService: ProductServicing!
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
                  reachability: RxClassicReachable                  
        ) {
        self.channelUuid = channelUuid
        self.productService = productService
        self.reachability = reachability
        setupDataSource()
    }
    
    func setupDataSource() {
        
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
                    icon = "creation"
                case MediaCategory.testimony.rawValue:
                    icon = "creation"
                case MediaCategory.tutorial.rawValue:
                    icon = "creation"
                case MediaCategory.conference.rawValue:
                    icon = "creation"
                default:
                    icon = "creation"
                }
                return PlaylistItemType.drillIn(type: .playlistItemType(item: $0), iconName: icon, title: $0.localizedname, showBottomSeparator: true)
                }
            }
            .next { [unowned self] list in
                self.sections.value = [
                    PlaylistSectionViewModel(type: .playlist, items: list)
                ]
            }.disposed(by: self.bag)
        
        self.fetchPlaylist(offset: lastOffset + 1, limit: Constants.limit, cacheRule: .fetchAndAppend)
        
        reactToReachability()
    }
    
    func fetchPlaylist(offset: Int, limit: Int, cacheRule: CacheRule) {
        productService.fetchPlaylists(for: self.channelUuid, offset:  offset, limit: limit, cacheRule: cacheRule).subscribe(onSuccess: { (playlistResponse, playlists) in
            DDLogDebug("fetchPlaylists: \(playlists)")
            self.playlists.value.append(contentsOf: playlists)
            self.totalEntries = playlistResponse.totalEntries
            self.totalPages = playlistResponse.totalPages
            self.pageSize = playlistResponse.pageSize
            self.pageNumber = playlistResponse.pageNumber

            self.lastOffset += 1
        }) { error in
            DDLogDebug("fetchPlaylists failed with error: \(error.localizedDescription)")
        }.disposed(by: self.bag)
    }
    
    private func reactToReachability() {
        reachability.startNotifier().asObservable()
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
            }).disposed(by: bag)
    }
}
