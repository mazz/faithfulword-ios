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
    
    private let channelUuid: String!
    private let productService: ProductServicing!
    
    private var bag = DisposeBag()
    
    internal init(channelUuid: String,
                  productService: ProductServicing) {
        self.channelUuid = channelUuid
        self.productService = productService
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
        
        self.fetchPlaylist(stride: 50)
    }
    
    func fetchPlaylist(stride: Int) {
        productService.fetchPlaylists(for: self.channelUuid).subscribe(onSuccess: { playlists in
            DDLogDebug("fetchPlaylists: \(playlists)")
            self.playlists.value = playlists
        }) { error in
            DDLogDebug("fetchPlaylists failed with error: \(error.localizedDescription)")
        }.disposed(by: self.bag)
    }
}
