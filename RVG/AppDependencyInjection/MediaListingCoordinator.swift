import Foundation
import RxSwift
import RxCocoa
import LNPopupController
import AVFoundation
import os.log

public final class MediaListingCoordinator {
    
    // MARK: Fields
    internal var playlistId: String?
    internal var mediaCategory: MediaCategory?
    internal var playable: Playable?
    internal var navigationController: UINavigationController?
    internal var mediaListingViewController: MediaListingViewController?
    internal var mediaSearchingViewController: MediaSearchResultsViewController?

    private var mediaListingFlowCompletion: FlowCompletion!

    private let bag = DisposeBag()
    
    // MARK: Dependencies
    
    private let resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>
    private let resettableMediaDetailsCoordinator: Resettable<MediaDetailsCoordinator>
    private let uiFactory: AppUIMaking
    
    internal init(uiFactory: AppUIMaking,
                  resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>,
                  resettableMediaDetailsCoordinator: Resettable<MediaDetailsCoordinator>) {
        self.uiFactory = uiFactory
        self.resettablePlaybackCoordinator = resettablePlaybackCoordinator
        self.resettableMediaDetailsCoordinator = resettableMediaDetailsCoordinator
    }
}

// MARK: <NavigationCoordinating>
extension MediaListingCoordinator: NavigationCoordinating {
    public func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        // 1. Hang on to the completion block for when the user if done with now-playing.
        mediaListingFlowCompletion = completion
        
        if let playlistId = playlistId,
            let mediaCategory = mediaCategory {
            self.mediaListingViewController = self.uiFactory.makeMediaListing(playlistId: playlistId, mediaCategory: mediaCategory)

            if let mediaListingViewController = self.mediaListingViewController {
                setup(mediaListingViewController)
                self.navigationController = mediaListingViewController.navigationController
                
                handle(eventsFrom: mediaListingViewController.viewModel)
            }

            self.mediaSearchingViewController = self.uiFactory.makeMediaSearching(playlistId: playlistId, mediaCategory: mediaCategory)
            if let mediaSearchingViewController: MediaSearchResultsViewController = self.mediaSearchingViewController {
                self.mediaListingViewController?.mediaSearchResultsViewController = self.mediaSearchingViewController
                handle(eventsFrom: mediaSearchingViewController.viewModel)
            }
        }
    }

    private func swapInMediaDetailsFlow(for playable: Playable) {
        self.resettableMediaDetailsCoordinator.value.playable = playable
        self.resettableMediaDetailsCoordinator.value.navigationController = self.navigationController

            self.resettableMediaDetailsCoordinator.value.flow(with: { mediaDetailsViewController in
                
                let detailsController = mediaDetailsViewController as! MediaDetailsViewController
                if let navController = self.navigationController {
                    navController.pushViewController(
                        detailsController,
                        animated: true
                    )
                }
                
            }, completion: { _ in
                self.navigationController!.dismiss(animated: true)
                self.resettableMediaDetailsCoordinator.reset()
                
            }, context: .other)
    }

    private func swapInPlaybackFlow(for playable: Playable) {
        if let mainCoordinator: MainCoordinator = dependencyModule.resolver.resolve(MainCoordinator.self),
            let popupController = mainCoordinator.popupController,
            let navigationController = mainCoordinator.mainNavigationController {
            // this assignment is meant to initiate the entire playbackAsset to assetPlaybackManager
            // assignment and loading of the historyPlayable
            popupController.playbackViewModel.selectedPlayable.value = playable
            //                let presenterName = playable.presenterName,
            if let thumbImage = UIImage(named: "creation") {
                popupController.shouldAutostartPlayback = true
                popupController.popupItem.title = playable.localizedname
                popupController.popupItem.subtitle = playable.presenter_name ?? "Unknown"
                popupController.popupItem.image = thumbImage
                //                popupController.albumArt = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
                //                popupController.fullAlbumArtImageView.image = thumbImage
                popupController.popupItem.accessibilityHint = NSLocalizedString("Tap to Expand the Mini Player", comment: "").l10n()
                
//                if let navigationController = self.navigationController {
                    navigationController.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "").l10n()
                    navigationController.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
                    navigationController.popupBar.imageView.layer.cornerRadius = 5
                if navigationController.popupContent == nil {
                    os_log("MediaListingCoordinator navigationController.popupContent: %{public}@", log: OSLog.data, String(describing: navigationController.popupContent))
                    navigationController.presentPopupBar(withContentViewController: popupController, animated: true, completion: nil)
                }
//                }
            }
        }
            
//        self.resettablePlaybackCoordinator.value.flow(with: { playbackViewController in
//            // do nothing because the bottom popup should appear
//            // when the playbackViewController loads
//
//            let popupController = playbackViewController as! PopupContentController
//
////            // this assignment is meant to initiate the entire playbackAsset to assetPlaybackManager
////            // assignment and loading of the historyPlayable
////            popupController.playbackViewModel.selectedPlayable.value = playable
////
////
//////                let presenterName = playable.presenterName,
////            if let thumbImage = UIImage(named: "creation") {
////                popupController.popupItem.title = playable.localizedname
////                popupController.popupItem.subtitle = playable.presenter_name ?? "Unknown"
////                popupController.popupItem.image = thumbImage
////                //                popupController.albumArt = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
//////                popupController.fullAlbumArtImageView.image = thumbImage
////                popupController.popupItem.accessibilityHint = NSLocalizedString("Tap to Expand the Mini Player", comment: "").l10n()
////
////                if let navigationController = self.navigationController {
////                    navigationController.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "").l10n()
////                    navigationController.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
////                    navigationController.popupBar.imageView.layer.cornerRadius = 5
////                    navigationController.presentPopupBar(withContentViewController: popupController, animated: true, completion: nil)
////                }
////            }
//
//        }, completion: { _ in
//            self.navigationController!.dismiss(animated: true)
//            self.resettablePlaybackCoordinator.reset()
//
//        }, context: .other)
    }

    func goToPlayback(for playable: Playable) {
        DDLogDebug("goToPlayback playable: \(playable)")

//        guard let _ = playable.localizedName
//            let _ = playable.presenterName
//            else { return }

        self.resettablePlaybackCoordinator.value.navigationController = self.navigationController!

        swapInPlaybackFlow(for: playable)
    }

    func goToMediaListing(for playable: Playable) {
        DDLogDebug("goToMediaListing playable: \(playable)")
        
        //        guard let _ = playable.localizedName
        //            let _ = playable.presenterName
        //            else { return }
        
        self.resettablePlaybackCoordinator.value.navigationController = self.navigationController!
        
        swapInMediaDetailsFlow(for: playable)
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
    
    private func handle(eventsFrom mediaSearchingViewModel: MediaSearchViewModel) {
        DDLogDebug("handle(eventsFrom mediaSearchingViewModel")
        mediaSearchingViewModel.drillInEvent.next { [unowned self] type in
            switch type {
            case .playable(let item):
                DDLogDebug(".defaultType: \(item)")
//                self.goToMediaListing(for: item)
                self.swapInMediaDetailsFlow(for: item)
            default:
                break
            }
            }.disposed(by: bag)
    }
}

