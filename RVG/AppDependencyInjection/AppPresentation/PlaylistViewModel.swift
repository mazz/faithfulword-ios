import Foundation
import RxSwift

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
        self.fetchPlaylist(stride: 50)
    }
    
    // MARK: Dependencies
    
//    private let playlistType: PlaylistType!
    private let channelUuid: String!
    private let productService: ProductServicing!
    
    private var bag = DisposeBag()
    
    internal init(channelUuid: String,
                  productService: ProductServicing) {
//        self.playlistType = playlistType
        self.channelUuid = channelUuid
        self.productService = productService
        setupDataSource()
    }
    
    func setupDataSource() {
        
        self.playlists.asObservable()
            .map { $0.map {
                var icon: String = "feetprint"
                
//                switch self.playlistType {
//                case .gospel?:
//                    icon = "feetprint"
//                case .music?:
//                    icon = "disc_icon_white"
//                case .preaching?:
//                    icon = "preaching"
//                default:
//                    icon = "feetprint"
//                }
                return PlaylistItemType.drillIn(type: .playlistItemType(item: $0), iconName: icon, title: $0.localizedname, showBottomSeparator: true)
                }
            }
            .next { [unowned self] list in
                self.sections.value = [
                    PlaylistSectionViewModel(type: .playlist, items: list)
                ]
            }.disposed(by: self.bag)
        
        self.fetchPlaylist(stride: 50)
    }
    
    func fetchPlaylist(stride: Int) {
        
        productService.fetchPlaylists(for: self.channelUuid).subscribe(onSuccess: { playlists in
            DDLogDebug("fetchPlaylists: \(playlists)")
        }) { error in
            DDLogDebug("fetchPlaylists failed with error: \(error.localizedDescription)")
        }
        
//        switch self.playlistType {
//        case .gospel?:
//            DDLogDebug("gospel")
//
////            self.productService.fetchPlaylist(for: .gospel, stride: 50).subscribe(onSuccess: { listing in
////                self.playlists.value = listing
////            }) { error in
////                DDLogDebug("fetchPlaylist failed with error: \(error.localizedDescription)")
////                }.disposed(by: self.bag)
//        case .music?:
//            DDLogDebug("music")
////            self.productService.fetchPlaylist(for: .music, stride: 50).subscribe(onSuccess: { listing in
////                self.playlists.value = listing
////            }) { error in
////                DDLogDebug("fetchPlaylist failed with error: \(error.localizedDescription)")
////                }.disposed(by: self.bag)
//        case .preaching?:
//            DDLogDebug("preaching")
//        default:
//            DDLogDebug("feetprint")
//        }
    }
}
