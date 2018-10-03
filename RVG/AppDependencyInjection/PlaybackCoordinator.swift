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

    public func updatePlaybackAsset(_ playable: Playable) {
        guard let localizedName = playable.localizedName,
            let presenterName = playable.presenterName,
            let path = playable.path,
            let assetPlaybackService = self.assetPlaybackService,
            let url = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path))
            else {
                return
        }
        assetPlaybackService.assetPlaybackManager.stop()
        assetPlaybackService.assetPlaybackManager.asset = Asset(assetName: localizedName,
                                                                artist: presenterName,
                                                                urlAsset: AVURLAsset(url: url))
    }
}

extension PlaybackCoordinator: NavigationCoordinating {
    func flow(with setup: (UIViewController) -> Void, completion: @escaping FlowCompletion, context: FlowContext) {
        playbackFlowCompletion = completion

        self.popupContentController = self.uiFactory.makePopupPlayer()
        setup(self.popupContentController!)
    }
}

