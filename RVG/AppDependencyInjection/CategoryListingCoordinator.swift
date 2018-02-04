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
        }
    }
}

