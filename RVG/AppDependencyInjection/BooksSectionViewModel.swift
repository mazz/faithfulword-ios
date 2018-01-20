import Foundation
import RxDataSources

internal struct BooksSectionViewModel {
    internal let type: BooksSectionType
    internal let items: [BooksItemType]
}

internal enum BooksSectionType {
    case book
    case debug
}

internal enum BooksItemType {
//    case field(String, String)
//    case option(SettingOptionType)
//    case action(name: String)
    case drillIn(type: BooksDrillInType, iconName: String, title: String, showBottomSeparator: Bool)
//    case info(String)
}

public enum BooksDrillInType {
    case bookType(bookId: String)
}

extension BooksSectionViewModel: SectionModelType {
    typealias Item = BooksItemType
    init(original: BooksSectionViewModel, items: [Item]) {
        self.type = original.type
        self.items = items
    }
}
