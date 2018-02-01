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
        
        handle(eventsFrom: sideMenuController.viewModel)
        setup(sideMenuController)
    }
}

extension SideMenuCoordinator {
    private func handle(eventsFrom sideMenuViewModel: SideMenuViewModel) {
        sideMenuViewModel.drillInEvent.next { [unowned self] type in
            switch type {
            case .bible:
                print(".bible")
            case .soulwinning:
                print(".soulwinning")
            case .music:
                print(".music")
            case .aboutUs:
                print(".aboutUs")
            case .share:
                print(".share")
            case .setBibleLanguage:
                print(".setBibleLanguage")
            case .donate:
                print(".donate")
            case .privacyPolicy:
                print(".privacyPolicy")
            case .contactUs:
                print(".contactUs")
            default:
                break
            }
            }.disposed(by: bag)
    }
}
