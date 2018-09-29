import Foundation
import RxSwift
import RxCocoa
import LNPopupController

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

            let popupController = playbackViewController as! DemoMusicPlayerController

            if let localizedName = playable.localizedName,
                let presenterName = playable.presenterName,
                let thumbImage = UIImage(named: "titus1-9_thumb_lg")
            {
                popupController.songTitle = localizedName
                popupController.albumTitle = presenterName
                popupController.albumArt = thumbImage
                popupController.popupItem.accessibilityHint = NSLocalizedString("Tap to Expand the Mini Player", comment: "")

                if let navigationController = self.navigationController {
                    navigationController.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "")

                    //                navigationController.popupItem.title = localizedName
                    //                navigationController.popupItem.subtitle = presenterName

                    //                print("navigationController.popupItem.title: \(navigationController.popupItem.title)")
                    //                print("navigationController.popupItem.subtitle: \(navigationController.popupItem.subtitle)")

                    //                navigationController.popupBar.barStyle = .compact
                    navigationController.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
                    navigationController.popupBar.imageView.layer.cornerRadius = 5
                    navigationController.presentPopupBar(withContentViewController: popupController, animated: true, completion: nil)

                }

                self.resettablePlaybackCoordinator.value.updatePlaybackAsset(playable)
            }

        }, completion: { _ in
            self.navigationController!.dismiss(animated: true)
            self.resettablePlaybackCoordinator.reset()

        }, context: .other)
    }

    func goToPlayback(for playable: Playable) {
        print("goToPlayback playable: \(playable)")

        guard let _ = playable.localizedName,
            let _ = playable.presenterName
            else { return }

        //        self.resettablePlaybackCoordinator.value.playableItem = playable
        self.resettablePlaybackCoordinator.value.navigationController = self.navigationController!
        
        swapInPlaybackFlow(for: playable)

        //        let popupContentController = self.uiFactory.makePopupPlayer()
        //        popupContentController.songTitle = localizedName
        //        popupContentController.albumTitle = presenterName
        //        popupContentController.albumArt = UIImage(named: "titus1-9_thumb_lg")!//images[(indexPath as NSIndexPath).row]
        //        popupContentController.popupItem.accessibilityHint = NSLocalizedString("Double Tap to Expand the Mini Player", comment: "")
        //
        //        self.navigationController?.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "")
        //
        //        self.navigationController?.popupBar.barStyle = .compact
        //        self.navigationController?.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
        //        self.navigationController?.popupBar.imageView.layer.cornerRadius = 5
        //        self.navigationController?.presentPopupBar(withContentViewController: popupContentController, animated: true, completion: nil)

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

