import Foundation
import RxSwift

internal final class CategoryListingCoordinator {
    // MARK: Dependencies

    private let uiFactory: AppUIMaking

    // MARK: Fields
    internal var categoryType: CategoryListingType?
    private let bag = DisposeBag()

    internal init(uiFactory: AppUIMaking) {
        self.uiFactory = uiFactory
    }
}

extension CategoryListingCoordinator: NavigationCoordinating {
    public func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        if let mediaType = self.categoryType {
            let categoryListingViewController = uiFactory.makeCategoryListing(categoryType: mediaType)
            setup(categoryListingViewController)
            handle(eventsFrom: categoryListingViewController.viewModel)
        }
    }

    func goToCategory(for categorizable: Categorizable) {
        print("goToCategory categorizable: \(categorizable)")
    }

}

// MARK: Event handling for medialisting screen
extension CategoryListingCoordinator {
    private func handle(eventsFrom categoryListingViewModel: CategoryListingViewModel) {
        print("handle(eventsFrom categoryListingViewModel")
        categoryListingViewModel.drillInEvent.next { [unowned self] type in
            switch type {
            case .categoryItemType(let item):
                self.goToCategory(for: item)
                print("categoryItem: \(item)")
            }
            }.disposed(by: bag)
    }
}


