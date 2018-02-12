import Foundation
import RxSwift

internal final class BibleLanguageCoordinator  {
    // MARK: Dependencies

    internal let uiFactory: AppUIMaking

    // MARK: Fields
    private let bag = DisposeBag()

    internal init(uiFactory: AppUIMaking) {
        self.uiFactory = uiFactory
    }
}

extension BibleLanguageCoordinator: NavigationCoordinating {
    internal func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        let bibleLanguageController = uiFactory.makeBibleLanguagePage()
        setup(bibleLanguageController)
    }
}

