import Foundation
import RxSwift

internal final class PlaybackCoordinator  {
    // MARK: Dependencies
    internal let uiFactory: AppUIMaking

    // MARK: Fields
    internal var playableItem: Playable?
    internal var playbackFlowCompletion: FlowCompletion!
    internal var navigationController: UINavigationController?

    private let bag = DisposeBag()

    internal init(uiFactory: AppUIMaking) {
        self.uiFactory = uiFactory
    }
}

extension PlaybackCoordinator: NavigationCoordinating {
    func flow(with setup: (UIViewController) -> Void, completion: @escaping FlowCompletion, context: FlowContext) {
        playbackFlowCompletion = completion

        if let localizedName = self.playableItem?.localizedName,
            let presenterName = self.playableItem?.presenterName,
            let thumbImage = UIImage(named: "titus1-9_thumb_lg")
        {
//            print("localizedName: \(localizedName)")
//            print("presenterName: \(presenterName)")

            let popupContentController = self.uiFactory.makePopupPlayer()

            popupContentController.songTitle = localizedName
            popupContentController.albumTitle = presenterName
            popupContentController.albumArt = thumbImage
            popupContentController.popupItem.accessibilityHint = NSLocalizedString("Tap to Expand the Mini Player", comment: "")

            if let navigationController = self.navigationController {
                navigationController.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "")

                navigationController.popupItem.title = localizedName
                navigationController.popupItem.subtitle = presenterName

//                print("navigationController.popupItem.title: \(navigationController.popupItem.title)")
//                print("navigationController.popupItem.subtitle: \(navigationController.popupItem.subtitle)")

                navigationController.popupBar.barStyle = .compact
                navigationController.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
                navigationController.popupBar.imageView.layer.cornerRadius = 5
                navigationController.presentPopupBar(withContentViewController: popupContentController, animated: true, completion: nil)
            }

            setup(popupContentController)
        }
    }
}

