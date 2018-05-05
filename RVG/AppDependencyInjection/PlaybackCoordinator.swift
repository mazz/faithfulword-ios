import Foundation
import RxSwift

internal final class PlaybackCoordinator  {
    // MARK: Dependencies
    internal let uiFactory: AppUIMaking

    // MARK: Fields
    internal var playableItem: Playable?
    internal var playbackFlowCompletion: FlowCompletion!
    internal var navigationController: UINavigationController?
    internal var popupContentController: DemoMusicPlayerController?

    private let bag = DisposeBag()

    internal init(uiFactory: AppUIMaking) {
        self.uiFactory = uiFactory
    }
}

extension PlaybackCoordinator: NavigationCoordinating {
    func flow(with setup: (UIViewController) -> Void, completion: @escaping FlowCompletion, context: FlowContext) {
        playbackFlowCompletion = completion

        self.popupContentController = self.uiFactory.makePopupPlayer()
        setup(self.popupContentController!)
    }
}

