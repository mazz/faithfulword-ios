import Foundation
import RxSwift
import AVFoundation

internal final class PlaybackCoordinator  {
    // MARK: Dependencies
    internal let uiFactory: AppUIMaking

    // MARK: Fields
    internal var playableItem: Playable?
    internal var playbackFlowCompletion: FlowCompletion!
    internal var navigationController: UINavigationController?
    internal var popupContentController: PopupContentController?

    internal let assetPlaybackService: AssetPlaybackServicing?

    private let bag = DisposeBag()

    internal init(uiFactory: AppUIMaking,
                  assetPlaybackService: AssetPlaybackServicing
        ) {
        self.uiFactory = uiFactory
        self.assetPlaybackService = assetPlaybackService
    }
}

extension PlaybackCoordinator: NavigationCoordinating {
    func flow(with setup: (UIViewController) -> Void, completion: @escaping FlowCompletion, context: FlowContext) {
        playbackFlowCompletion = completion

        self.popupContentController = self.uiFactory.makePopupPlayer()
        setup(self.popupContentController!)
    }
}

