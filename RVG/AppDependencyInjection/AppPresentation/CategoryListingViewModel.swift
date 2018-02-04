import Foundation
import RxSwift

final class CategoryListingViewModel {

    public func section(at index: Int) -> CategoryListingSectionViewModel {
        return sections.value[index]
    }

    public func item(at indexPath: IndexPath) -> CategoryListingItemType {
        return section(at: indexPath.section).items[indexPath.item]
    }

    public private(set) var categoryListing = Field<[Categorizable]>([])

    public private(set) var sections = Field<[CategoryListingSectionViewModel]>([])
    public let selectItemEvent = PublishSubject<IndexPath>()

    public var drillInEvent: Observable<CategoryListingDrillInType> {
        // Emit events by mapping a tapped index path to setting-option.
        return self.selectItemEvent.filterMap { [unowned self] indexPath -> CategoryListingDrillInType? in
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

    private let categoryListingType: CategoryListingType!
    private let productService: ProductServicing!

    private var bag = DisposeBag()

    internal init(categoryType: CategoryListingType,
                  productService: ProductServicing) {
        self.categoryListingType = categoryType
        self.productService = productService
        setupDataSource()
    }

    func setupDataSource() {

        self.categoryListing.asObservable()
            .map { $0.map {
                var icon: String = "feetprint"

                switch self.categoryListingType {
                case .gospel:
                    icon = "feetprint"
                case .music:
                    icon = "disc_icon_white"
                case .churches:
                    icon = "preaching"
                default:
                    icon = "feetprint"
                }
                return CategoryListingItemType.drillIn(type: .categoryItemType(item: $0), iconName: icon, title: $0.localizedTitle, showBottomSeparator: true)
            }
            }
            .next { [unowned self] list in
                self.sections.value = [
                    CategoryListingSectionViewModel(type: .category, items: list)
                ]
            }.disposed(by: self.bag)

        self.productService.fetchCategoryListing(for: .gospel).subscribe(onSuccess: { listing in
            self.categoryListing.value = listing
        }) { error in
            print("fetchCategoryListing failed with error: \(error.localizedDescription)")
        }.disposed(by: self.bag)
    }
}
