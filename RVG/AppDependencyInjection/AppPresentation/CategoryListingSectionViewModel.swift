import Foundation
import RxDataSources

internal struct CategoryListingSectionViewModel {
    internal let type: CategoryListingSectionType
    internal let items: [CategoryListingItemType]
}

internal enum CategoryListingSectionType {
    case category
    case debug
}

internal enum CategoryListingItemType {
    case drillIn(type: CategoryListingDrillInType, iconName: String, title: String, showBottomSeparator: Bool)
}

public enum CategoryListingDrillInType {
    case categoryItemType(item: Categorizable)
}

extension CategoryListingSectionViewModel: SectionModelType {
    typealias Item = CategoryListingItemType
    init(original: CategoryListingSectionViewModel, items: [Item]) {
        self.type = original.type
        self.items = items
    }
}

