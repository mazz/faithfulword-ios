import Foundation
import RxDataSources

public enum RadioListSectionType {
    case list
}

public enum RadioListItemType {
    case selectable(header: String, isSelected: Bool)
}

public struct RadioListSectionViewModel {
    public let type: RadioListSectionType
    public let items: [RadioListItemType]
}

extension RadioListSectionViewModel: SectionModelType {
    public typealias Item = RadioListItemType
    public init(original: RadioListSectionViewModel, items: [Item]) {
        self.type = original.type
        self.items = items
    }
}
