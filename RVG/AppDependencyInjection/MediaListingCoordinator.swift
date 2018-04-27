import Foundation
import RxSwift
import RxCocoa
import LNPopupController

public final class MediaListingCoordinator {
    
    // MARK: Fields
    internal var playlistId: String?
    internal var mediaType: MediaType?

    private var navigationController: UINavigationController?
    private var mediaListingFlowCompletion: FlowCompletion!
    private let bag = DisposeBag()
    
    // MARK: Dependencies
    
    private let uiFactory: AppUIMaking
    
    internal init(uiFactory: AppUIMaking) {
        self.uiFactory = uiFactory
    }
}

// MARK: <NavigationCoordinating>
extension MediaListingCoordinator: NavigationCoordinating {
    public func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        // 1. Hang on to the completion block for when the user if done with now-playing.
        mediaListingFlowCompletion = completion
        
        if let playlistId = playlistId, let mediaType = mediaType {
            let mediaListingViewController = self.uiFactory.makeMediaListing(playlistId: playlistId, mediaType: mediaType)
            setup(mediaListingViewController)

            self.navigationController = mediaListingViewController.navigationController

            handle(eventsFrom: mediaListingViewController.viewModel)
        }
    }
    
    func goToPlayback(for playable: Playable) {
        print("goToPlayback playable: \(playable)")

        guard let localizedName = playable.localizedName,
            let presenterName = playable.presenterName
            else { return }
        let popupContentController = self.uiFactory.makePopupPlayer()
        popupContentController.songTitle = localizedName
        popupContentController.albumTitle = presenterName
//        popupContentController.albumArt = images[(indexPath as NSIndexPath).row]
        popupContentController.popupItem.accessibilityHint = NSLocalizedString("Double Tap to Expand the Mini Player", comment: "")

        self.navigationController?.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "")

        self.navigationController?.presentPopupBar(withContentViewController: popupContentController, animated: true, completion: nil)
        self.navigationController?.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
        self.navigationController?.popupBar.imageView.layer.cornerRadius = 5

    }
}

// MARK: Event handling for medialisting screen
extension MediaListingCoordinator {
    private func handle(eventsFrom mediaListingViewModel: MediaListingViewModel) {
        print("handle(eventsFrom mediaListingViewModel")
        mediaListingViewModel.drillInEvent.next { [unowned self] type in
            switch type {
            case .playable(let item):
                print(".defaultType: \(item)")
                self.goToPlayback(for: item)
            default:
                break
            }
            }.disposed(by: bag)
    }
}

