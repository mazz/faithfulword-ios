import Foundation
import RxSwift

internal final class CategoryListingCoordinator {
    // MARK: Dependencies

    private let uiFactory: AppUIMaking
    private let resettableMediaListingCoordinator: Resettable<MediaListingCoordinator>

    // MARK: Fields
    internal var categoryType: CategoryListingType?
    internal var mainNavigationController: UINavigationController!
    private let bag = DisposeBag()

    internal init(uiFactory: AppUIMaking,
                  resettableMediaListingCoordinator: Resettable<MediaListingCoordinator>
                  ) {
        self.uiFactory = uiFactory
        self.resettableMediaListingCoordinator = resettableMediaListingCoordinator
    }
}

extension CategoryListingCoordinator: NavigationCoordinating {
    public func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        if let mediaType = self.categoryType {

            let categoryListingViewController = uiFactory.makeCategoryListing(categoryType: mediaType)
//            mainNavigationController = UINavigationController(rootViewController: categoryListingViewController)

            setup(categoryListingViewController)
            handle(eventsFrom: categoryListingViewController.viewModel)
        }
    }

    func goToCategory(for categorizable: Categorizable) {
        DispatchQueue.main.async {
            print("goToCategory categorizable: \(categorizable)")
            self.resettableMediaListingCoordinator.value.playlistId = categorizable.categoryUuid
            self.resettableMediaListingCoordinator.value.mediaType = .audioGospel
            self.resettableMediaListingCoordinator.value.flow(with: { viewController in

                self.mainNavigationController.pushViewController(
                    viewController,
                    animated: true
                )
                //            self.mainNavigationController.present(viewController, animated: true)
            }, completion: { _ in
                self.mainNavigationController.dismiss(animated: true)
                self.resettableMediaListingCoordinator.reset()
                //            self.resettableSplashScreenCoordinator.reset()

            }, context: .push(onto: self.mainNavigationController))
        }
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


