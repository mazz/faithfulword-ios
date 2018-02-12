import Foundation
import RxDataSources

internal struct BibleLanguageSectionViewModel {
    internal let type: BibleLanguageSectionType
    internal let items: [BibleLanguageItemType]
}

internal enum BibleLanguageSectionType {
    case languages
}

internal enum BibleLanguageItemType {
    case language(type: BibleLanguageLanguageType, body: String)
}

public enum BibleLanguageLanguageType {
    case defaultLanguageType
}

extension BibleLanguageSectionViewModel: SectionModelType {
    typealias Item = BibleLanguageItemType
    init(original: BibleLanguageSectionViewModel, items: [Item]) {
        self.type = original.type
        self.items = items
    }
}

public struct BibleLanguageItem {
    public var heading: BibleLanguageLanguageType
}
