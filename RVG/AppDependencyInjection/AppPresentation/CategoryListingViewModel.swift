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
                return CategoryListingItemType.drillIn(type: .categoryItemType(categoryItemUuid: $0.uuid), iconName: icon, title: $0.localizedTitle, showBottomSeparator: true)
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
