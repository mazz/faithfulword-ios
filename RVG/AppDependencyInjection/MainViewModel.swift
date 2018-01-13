import RxSwift
//import BoseMobileModels
//import BoseMobileCore
//import BoseMobilePresentation
//import BoseMobileCommunication

internal final class MainViewModel {
    // MARK: Fields
    
    internal var books: Observable<[Book]> {
        return productService.userBooks.asObservable()
    }

    internal var persistedBooks: Observable<[Book]> {
        return productService.persistedUserBooks.asObservable()
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
    
    // MARK: Dependencies
    private let productService: ProductServicing!
    private let bag = DisposeBag()

    internal init(productService: ProductServicing) {
        self.productService = productService
        setupDatasource()

//        sections.value = sectionViewModels
    }
    
//    private var sectionViewModels: Observable<[BooksSectionViewModel]> {
//        return books.map { books in
//            let sectionViewModels = [
//                BooksSectionViewModel(type: .book,
//                                     items: books.map { BookItemType.action(name: $0.title) })
//            ]
//            return sectionViewModels
//        }
//    }
    
    private func setupDatasource() {
        // TODO: CASTLE-4739 - JT/RL Figure out proper mapping between connection type, product, and regime (Rio or Riv)
//        let productType: ProductType = device.discoveredDevice.connectionType == .webSocket ? .eddie : .goodyear
        productService.persistedUserBooks.asObservable()
            .map { $0.map { BooksItemType.drillIn(type: .defaultType, iconName: "book", title: $0.localizedTitle, showBottomSeparator: true) } }
            .next { [unowned self] names in
                self.sections.value = [
                    BooksSectionViewModel(type: .book, items: names)
                ]
            }.disposed(by: bag)
//            .map { $0.map { NameDeviceItemType.suggestedName($0) } }
//            .next { [unowned self] names in
//                self.sections.value = [NameDeviceSectionViewModel(type: .device, items: []),
//                                       NameDeviceSectionViewModel(type: .suggestedNames, items: names),
//                                       NameDeviceSectionViewModel(type: .customName, items: [.customName])]
//            }.disposed(by: bag)
    }
    
//    private var sectionViewModels: [BooksSectionViewModel] {
//        var sectionViewModels = [
//            BooksSectionViewModel(type: .book, items: [
//                .action(.name)
//                ])
//        ]
//        #if DEBUG
//            let debugSection = BooksSectionViewModel(type: .debug, items: [
//
//                ])
//            sectionViewModels.append(debugSection)
//        #endif
//        return sectionViewModels
//    }

}
