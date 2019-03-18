import RxSwift

internal final class BooksViewModel {
    
    // MARK: Fields

    public var title = Field<String>(NSLocalizedString("Bible", comment: "").l10n()) //{
//        return Observable.just(NSLocalizedString("Bible", comment: "").l10n())
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
    
    public func fetchMoreBooks() {
        productService.fetchBooks(stride: 100).asObservable()
            .subscribeAndDispose(by: self.bag)
    }
    
    // MARK: Dependencies
    
    private let productService: ProductServicing
    private let languageService: LanguageServicing
    
    private var bag = DisposeBag()

    internal init(productService: ProductServicing,
                  languageService: LanguageServicing
        ) {
        self.productService = productService
        self.languageService = languageService

        self.languageService.userLanguage.asObservable()
            .next { [unowned self] identifier in
                self.title.value = NSLocalizedString("Bible", comment: "").l10n()
                productService.fetchBooks(stride: 100).asObservable()
                    .subscribeAndDispose(by: self.bag)
        }.disposed(by: bag)

        setupDatasource()
    }
    
    // MARK: Private helpers

    private func setupDatasource() {
        // assume we are online and observe userBooks by default
        productService.userBooks.asObservable()
            .map { $0.map { BooksItemType.drillIn(type: .bookType(bookUuid: $0.categoryUuid), iconName: "book", title: $0.localizedTitle, showBottomSeparator: true) } }
            .next { [unowned self] names in
                self.sections.value = [
                    BooksSectionViewModel(type: .book, items: names)
                ]
            }.disposed(by: bag)
    }
}
