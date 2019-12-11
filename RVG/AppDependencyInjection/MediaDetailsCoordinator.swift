//
//  MediaDetailsCoordinator.swift
//  FaithfulWord
//
//  Created by Michael on 2019-09-02.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

internal final class MediaDetailsCoordinator  {
    // MARK: Dependencies
    private let resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>
    internal let uiFactory: AppUIMaking
    
    // MARK: Fields
    internal var playable: Playable?
//    internal var mediaCategory: MediaCategory?
    
    internal var navigationController: UINavigationController?
    internal var mediaDetailsViewController: MediaDetailsViewController?

    private var mediaListingFlowCompletion: FlowCompletion!
    
    private let bag = DisposeBag()
    
    internal init(uiFactory: AppUIMaking,
                  resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>) {
        self.uiFactory = uiFactory
        self.resettablePlaybackCoordinator = resettablePlaybackCoordinator
    }
}

extension MediaDetailsCoordinator: NavigationCoordinating {
    internal func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        if let playable = playable {
            self.mediaDetailsViewController = self.uiFactory.makeMediaDetails(playable: playable)
            if let mediaDetailsViewController: MediaDetailsViewController = self.mediaDetailsViewController {
                handle(eventsFrom: mediaDetailsViewController.viewModel)

                setup(mediaDetailsViewController)
            }
        }
    }
    
    private func swapInPlaybackFlow(for playable: Playable) {
        self.resettablePlaybackCoordinator.value.flow(with: { playbackViewController in
            // do nothing because the bottom popup should appear
            // when the playbackViewController loads
            
            let popupController = playbackViewController as! PopupContentController
            
            // this assignment is meant to initiate the entire playbackAsset to assetPlaybackManager
            // assignment and loading of the historyPlayable
            popupController.playbackViewModel.selectedPlayable.value = playable
            
            
            //                let presenterName = playable.presenterName,
            if let thumbImage = UIImage(named: "creation") {
                popupController.popupItem.title = playable.localizedname
                popupController.popupItem.subtitle = playable.presenter_name ?? "Unknown"
                popupController.popupItem.image = thumbImage
                //                popupController.albumArt = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
                //                popupController.fullAlbumArtImageView.image = thumbImage
                popupController.popupItem.accessibilityHint = NSLocalizedString("Tap to Expand the Mini Player", comment: "").l10n()
                
                if let navigationController = self.navigationController {
                    navigationController.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "").l10n()
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
        
        //        guard let _ = playable.localizedName
        //            let _ = playable.presenterName
        //            else { return }
        
        self.resettablePlaybackCoordinator.value.navigationController = self.navigationController!
        
        swapInPlaybackFlow(for: playable)
    }

}

// MARK: Event handling for medialisting screen
extension MediaDetailsCoordinator {
    private func handle(eventsFrom mediaDetailsViewModel: MediaDetailsViewModel) {
        DDLogDebug("handle(eventsFrom mediaDetailsViewModel")
        mediaDetailsViewModel.drillInEvent.next { [unowned self] type in
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
