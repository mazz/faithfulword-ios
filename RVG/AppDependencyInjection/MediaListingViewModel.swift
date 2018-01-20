import Foundation
import RxSwift

internal final class MediaListingViewModel {
    // MARK: Fields
    
    public private(set) var media = Field<[Playable]>([])
//    public private(set) var persistedMedia = Field<[Playable]>([])
//    public private(set) var mediaType: MediaType = MediaType.mediaChapter
    
    public private(set) var sections = Field<[MediaListingSectionViewModel]>([])

    public let selectItemEvent = PublishSubject<IndexPath>()
    
    public var drillInEvent: Observable<MediaListingDrillInType> {
        // Emit events by mapping a tapped index path to setting-option.
        return self.selectItemEvent.filterMap { [unowned self] indexPath -> MediaListingDrillInType? in
            let section = self.sections.value[indexPath.section]
            let item = section.items[indexPath.item]
            // Don't emit an event for anything that is not a 'drillIn'
            if case .drillIn(let type, _, _, _) = item {
                return type
            }
            return nil
        }
    }
    
    // MARK: Dependencies
    private let playlistId: String!
    private let mediaType: MediaType!
    private let productService: ProductServicing!
    private let bag = DisposeBag()
    
    internal init(playlistId: String,
                  mediaType: MediaType,
                  productService: ProductServicing) {
        self.playlistId = playlistId
        self.mediaType = mediaType
        self.productService = productService

        setupDatasource()
    }

    private func setupDatasource() {
        self.media.asObservable()
            .map { $0.map { MediaListingItemType.drillIn(type: .defaultType, iconName: "book", title: $0.localizedName!, showBottomSeparator: true) } }
            .next { [unowned self] names in
                self.sections.value = [
                    MediaListingSectionViewModel(type: .media, items: names)
                ]
            }.disposed(by: bag)
        
        self.productService.fetchChapters(for: self.playlistId)
            .map { [unowned self] in
                self.media.value = $0
                print("self.media.value: \(self.media.value)")
            }.asObservable()
            .subscribeAndDispose(by: self.bag)
    }
}
