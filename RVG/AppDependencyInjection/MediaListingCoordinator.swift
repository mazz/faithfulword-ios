import Foundation
import RxSwift
import RxCocoa
import LNPopupController
import AVFoundation

public final class MediaListingCoordinator {
    
    // MARK: Fields
    internal var playlistId: String?
    internal var mediaType: MediaType?
    internal var navigationController: UINavigationController?
    internal var mediaListingViewController: MediaListingViewController?

    private var mediaListingFlowCompletion: FlowCompletion!

    private let bag = DisposeBag()
    
    // MARK: Dependencies
    
    private let resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>
    private let uiFactory: AppUIMaking
    
    internal init(uiFactory: AppUIMaking,
                  resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>) {
        self.uiFactory = uiFactory
        self.resettablePlaybackCoordinator = resettablePlaybackCoordinator
    }
}

// MARK: <NavigationCoordinating>
extension MediaListingCoordinator: NavigationCoordinating {
    public func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        // 1. Hang on to the completion block for when the user if done with now-playing.
        mediaListingFlowCompletion = completion
        
        if let playlistId = playlistId, let mediaType = mediaType {
            self.mediaListingViewController = self.uiFactory.makeMediaListing(playlistId: playlistId, mediaType: mediaType)
            if let mediaListingViewController = self.mediaListingViewController {
                setup(mediaListingViewController)
                self.navigationController = mediaListingViewController.navigationController
                
                handle(eventsFrom: mediaListingViewController.viewModel)
            }
        }
    }

    private func swapInPlaybackFlow(for playable: Playable) {
        self.resettablePlaybackCoordinator.value.flow(with: { playbackViewController in
            // do nothing because the bottom popup should appear
            // when the playbackViewController loads

            let popupController = playbackViewController as! PopupContentController

            if let localizedName = playable.localizedName,
//                let presenterName = playable.presenterName,
                let thumbImage = UIImage(named: "creation") {
                popupController.popupItem.title = localizedName
                popupController.popupItem.subtitle = playable.presenterName ?? "Unknown"
                popupController.popupItem.image = thumbImage
                //                popupController.albumArt = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
//                popupController.fullAlbumArtImageView.image = thumbImage
                popupController.popupItem.accessibilityHint = NSLocalizedString("Tap to Expand the Mini Player", comment: "")

                if let navigationController = self.navigationController {
                    navigationController.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "")
                    navigationController.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
                    navigationController.popupBar.imageView.layer.cornerRadius = 5
                    navigationController.presentPopupBar(withContentViewController: popupController, animated: true, completion: nil)
                }
            }

        }, completion: { _ in
            self.navigationController!.dismiss(animated: true)
            self.resettablePlaybackCoordinator.reset()

        }, context: .other)
    }

    func goToPlayback(for playable: Playable) {
        DDLogDebug("goToPlayback playable: \(playable)")

        guard let _ = playable.localizedName
//            let _ = playable.presenterName
            else { return }

        self.resettablePlaybackCoordinator.value.navigationController = self.navigationController!

        swapInPlaybackFlow(for: playable)
    }
}

// MARK: Event handling for medialisting screen
extension MediaListingCoordinator {
    private func handle(eventsFrom mediaListingViewModel: MediaListingViewModel) {
        DDLogDebug("handle(eventsFrom mediaListingViewModel")
        mediaListingViewModel.drillInEvent.next { [unowned self] type in
            switch type {
            case .playable(let item):
                DDLogDebug(".defaultType: \(item)")
                self.goToPlayback(for: item)
            default:
                break
            }
            }.disposed(by: bag)
    }
}

