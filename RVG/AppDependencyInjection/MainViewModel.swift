import RxSwift
import Alamofire

internal final class MainViewModel {
    // MARK: Fields
    
//    internal var books: Observable<[Book]> {
//        return productService.userBooks.asObservable()
//    }

//    internal var persistedBooks: Observable<[Book]> {
//        return productService.persistedUserBooks.asObservable()
//    }

    public func section(at index: Int) -> BooksSectionViewModel {
        return sections.value[index]
    }
    
    public func item(at indexPath: IndexPath) -> BooksItemType {
        return section(at: indexPath.section).items[indexPath.item]
    }

    public private(set) var sections = Field<[BooksSectionViewModel]>([])
    public let selectItemEvent = PublishSubject<IndexPath>()

    public var drillInEvent: Observable<BooksDrillInType> {
        // Emit events by mapping a tapped index path to setting-option.
        return self.selectItemEvent.filterMap { [unowned self] indexPath -> BooksDrillInType? in
            let section = self.sections.value[indexPath.section]
            let item = section.items[indexPath.item]
            // Don't emit an event for anything that is not a 'drillIn'
            if case .drillIn(let type, _, _, _) = item {
                return type
            }
            return nil
        }
    }
    
    private let networkStatus = PublishSubject<Alamofire.NetworkReachabilityManager.NetworkReachabilityStatus>()

    // MARK: Dependencies
    private let productService: ProductServicing!
    private let reachability: RxReachable!
    
    private var bag = DisposeBag()

    internal init(productService: ProductServicing,
                  reachability: RxReachable) {
        self.productService = productService
        self.reachability = reachability
        
        reactToReachability()
        setupDatasource()
    }
    
    private func setupDatasource() {
        // assume we are online and observe userBooks by default
        productService.userBooks.asObservable()
            .map { $0.map { BooksItemType.drillIn(type: .defaultType, iconName: "book", title: $0.localizedTitle, showBottomSeparator: true) } }
            .next { [unowned self] names in
                self.sections.value = [
                    BooksSectionViewModel(type: .book, items: names)
                ]
            }.disposed(by: bag)
    }

    // MARK: Private helpers

    private func reactToReachability() {
        reachability.startListening().asObservable()
            .subscribe(onNext: { networkStatus in
                if networkStatus == .notReachable {
                    // dispose of bag for current productService.userBooks.asObservable
                    // observe the persistedUserBooks
                    print("MainViewModel reachability.notReachable")
                } else if networkStatus == .reachable(.ethernetOrWiFi) {
                    // dispose of bag for current productService.userBooks.asObservable
                    // observe the persistedUserBooks
                    print("MainViewModel reachability.reachable")
                }
            }).disposed(by: bag)
    }
}
