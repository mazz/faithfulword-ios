//
//  MediaRouteCoordinator.swift
//  FaithfulWord
//
//  Created by Michael on 2020-02-04.
//  Copyright © 2020 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift
import os.log

internal final class MediaRouteCoordinator  {
    
    
    // MARK: Dependencies
    private let resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>
    private let productService: ProductServicing
    internal let uiFactory: AppUIMaking
    
    // MARK: Fields
    internal var mediaRoute: MediaRoute?
    internal var mediaUniversalLink: MediaUniversalLink?
    internal var playable: Playable?
    //    internal var mediaCategory: MediaCategory?
    internal var navigationController: UINavigationController?
    internal var mediaDetailsViewController: MediaDetailsViewController?
    private var mediaListingFlowCompletion: FlowCompletion!
    private let bag = DisposeBag()
    internal init(uiFactory: AppUIMaking,
                  productService: ProductServicing,
                  resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>) {
        self.uiFactory = uiFactory
        self.productService = productService
        self.resettablePlaybackCoordinator = resettablePlaybackCoordinator
    }
}

extension MediaRouteCoordinator: NavigationCoordinating {
    internal func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        if let mediaRoute = mediaRoute {
            productService.fetchMediaItem(mediaItemUuid: mediaRoute.uuid)
                .subscribe(onSuccess: { [weak self] mediaItem in
                    os_log("fetched mediaItem:: %{public}@", log: OSLog.data, String(describing: mediaItem))
                    os_log("fetched mediaItem, mediaRoute.uuid %{public}@", log: OSLog.data, String(describing: mediaRoute.uuid))
                    self?.swapInPlaybackFlow(for: mediaItem)
                }).disposed(by: bag)
        } else if let mediaUniversalLink = mediaUniversalLink {
            productService.fetchMediaItemForHashId(hashId: mediaUniversalLink.hashId)
                .subscribe(onSuccess: { [weak self] mediaItem in
                    os_log("fetched mediaItem: %{public}@", log: OSLog.data, String(describing: mediaItem))
                    os_log("fetched mediaItem, mediaUniversalLink.hashId %{public}@", log: OSLog.data, String(describing: mediaUniversalLink.hashId))
                    self?.swapInPlaybackFlow(for: mediaItem)
                }).disposed(by: bag)
        }
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
                        os_log("MediaRouteCoordinator rootViewController.popupContent: %{public}@", log: OSLog.data, String(describing: navigationController.popupContent))
                        navigationController.presentPopupBar(withContentViewController: popupController, openPopup: true, animated: true, completion: nil)
                    } else {
                        navigationController.openPopup(animated: true, completion: nil)
                    }
                    //                }
                }
            }
        }
//    {
//        self.resettablePlaybackCoordinator.value.flow(with: { playbackViewController in
//            // do nothing because the bottom popup should appear
//            // when the playbackViewController loads
//
//            let popupController = playbackViewController as! PopupContentController
//            os_log("popupController: %{public}@", log: OSLog.data, String(describing: popupController))
//
//
//            // this assignment is meant to initiate the entire playbackAsset to assetPlaybackManager
//            // assignment and loading of the historyPlayable
//            popupController.playbackViewModel.selectedPlayable.value = playable
//
//
//            //                let presenterName = playable.presenterName,
//            if let thumbImage = UIImage(named: "creation") {
//                popupController.popupItem.title = playable.localizedname
//                popupController.popupItem.subtitle = playable.presenter_name ?? "Unknown"
//                popupController.popupItem.image = thumbImage
//                //                popupController.albumArt = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
//                //                popupController.fullAlbumArtImageView.image = thumbImage
//                popupController.popupItem.accessibilityHint = NSLocalizedString("Tap to Expand the Mini Player", comment: "").l10n()
//
//                if let navigationController = self.navigationController {
//                    os_log("navigationController: %{public}@", log: OSLog.data, String(describing: navigationController))
//                    navigationController.popupContentView.popupCloseButton.accessibilityLabel = NSLocalizedString("Dismiss Now Playing Screen", comment: "").l10n()
//                    navigationController.popupBar.tintColor = UIColor(white: 38.0 / 255.0, alpha: 1.0)
//                    navigationController.popupBar.imageView.layer.cornerRadius = 5
//                    //                    navigationController.presentPopupBar(withContentViewController: popupController, animated: true, completion: nil)
//                    navigationController.presentPopupBar(withContentViewController: popupController, openPopup: true, animated: true, completion: nil)
//                }
//            }
//
//        }, completion: { _ in
//            self.navigationController!.dismiss(animated: true)
//            self.resettablePlaybackCoordinator.reset()
//
//        }, context: .other)
//    }
    
    func goToPlayback(for playable: Playable) {
        DDLogDebug("goToPlayback playable: \(playable)")
        self.resettablePlaybackCoordinator.value.navigationController = self.navigationController!
        
        swapInPlaybackFlow(for: playable)
    }
    
}

// MARK: Event handling for medialisting screen
extension MediaRouteCoordinator {
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
