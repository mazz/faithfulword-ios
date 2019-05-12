import Foundation
import RxSwift

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
        fetchMedia(stride: 100)
//        productService.fetchBooks(offset: self.sections.value[0].items.count, limit: 50).asObservable()
//            .subscribeAndDispose(by: self.bag)
    }

    // MARK: Dependencies
    private let playlistId: String!
    private let mediaType: MediaType!
    private let productService: ProductServicing!
    private let assetPlaybackService: AssetPlaybackServicing!
//    private let assetPlaybackManager: AssetPlaybackManager!
//    private let remoteCommandManager: RemoteCommandManager!
    private let bag = DisposeBag()

    internal init(playlistId: String,
                  mediaType: MediaType,
                  productService: ProductServicing,
                  assetPlaybackService: AssetPlaybackServicing)
//        assetPlaybackManager: AssetPlaybackManager,
//        remoteCommandManager: RemoteCommandManager)
    {
        self.playlistId = playlistId
        self.mediaType = mediaType
        self.productService = productService
        self.assetPlaybackService = assetPlaybackService
//        self.assetPlaybackManager = assetPlaybackManager
//        self.remoteCommandManager = remoteCommandManager

        setupDatasource()
    }

    private func setupDatasource() {
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
                
                return MediaListingItemType.drillIn(type: .playable(item: $0), iconName: icon, title: $0.localizedName!, presenter: presenter, showBottomSeparator: true) }
            }
            .next { [unowned self] names in
                self.sections.value = [
                    MediaListingSectionViewModel(type: .media, items: names)
                ]
            }.disposed(by: bag)
        
        fetchMedia(stride: 100)
    }
    
    func fetchMedia(stride: Int) {
        switch self.mediaType {
        case .audioChapter?:
            self.productService.fetchChapters(for: self.playlistId, stride: 100).subscribe(onSuccess: { chapters in
                self.media.value = chapters
                self.assetPlaybackService.playables.value = self.media.value
            }, onError: { error in
                DDLogDebug("audioChapter failed with error: \(error.localizedDescription)")
            }).disposed(by: self.bag)
            //        case .audioSermon?:
        //            DDLogDebug("fetch .audioSermon")
        case .audioGospel?:
            self.productService.fetchMediaGospel(for: playlistId, stride: 100).subscribe(onSuccess: { mediaGospel in
                self.media.value = mediaGospel
                self.assetPlaybackService.playables.value = self.media.value
            }, onError: { error in
                DDLogDebug("audioGospel failed with error: \(error.localizedDescription)")
            }).disposed(by: self.bag)
        case .audioMusic?:
            self.productService.fetchMediaMusic(for: playlistId, stride: 100).subscribe(onSuccess: { mediaMusic in
                self.media.value = mediaMusic
                self.assetPlaybackService.playables.value = self.media.value
            }, onError: { error in
                DDLogDebug("audioMusic failed with error: \(error.localizedDescription)")
            }).disposed(by: self.bag)
        default:
            DDLogDebug("default")
        }
    }
}
