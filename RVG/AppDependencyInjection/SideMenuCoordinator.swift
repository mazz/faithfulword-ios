import Foundation
import RxSwift

internal final class SideMenuCoordinator  {
    // MARK: Dependencies

    private let uiFactory: AppUIMaking

    // MARK: Fields
    private let bag = DisposeBag()

    internal init(uiFactory: AppUIMaking) {
        self.uiFactory = uiFactory
    }
}

extension SideMenuCoordinator: NavigationCoordinating {
    internal func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        let sideMenuController = uiFactory.makeSideMenu()
        setup(sideMenuController)
    }
}
