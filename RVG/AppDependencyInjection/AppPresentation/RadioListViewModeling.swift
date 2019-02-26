import Foundation
import RxSwift

public protocol RadioListViewModeling {
    var sections: Observable<[RadioListSectionViewModel]> { get }
    var selectionEvent: PublishSubject<IndexPath> { get }
    var title: Observable<String> { get }
    var errorEvent: PublishSubject<Error> { get }
    
    func section(at index: Int) -> RadioListSectionViewModel
    func item(at indexPath: IndexPath) -> RadioListItemType
    func fetchMoreItems()
}
