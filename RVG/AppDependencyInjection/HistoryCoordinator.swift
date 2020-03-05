//
//  HistoryCoordinator.swift
//  FaithfulWord
//
//  Created by Michael on 2019-09-08.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

internal final class HistoryCoordinator  {
    // MARK: Dependencies
    
    internal let uiFactory: AppUIMaking
    private let resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>

    // MARK: Fields
    internal var historyViewController: HistoryViewController?
    internal var navigationController: UINavigationController?

    private let bag = DisposeBag()
    
    internal init(uiFactory: AppUIMaking,
                  resettablePlaybackCoordinator: Resettable<PlaybackCoordinator>) {
        self.uiFactory = uiFactory
        self.resettablePlaybackCoordinator = resettablePlaybackCoordinator
    }
}

extension HistoryCoordinator: NavigationCoordinating {
    internal func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        self.historyViewController = uiFactory.makeHistoryPage()

        if let historyController: HistoryViewController = self.historyViewController {
            handle(eventsFromHistoryPlaybackViewModel: historyController.playbackHistoryViewController.viewModel)
            handle(eventsFromHistoryDownloadViewModel: historyController.downloadHistoryViewController.viewModel)

            setup(historyController)
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
                popupController.shouldAutostartPlayback = true
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
extension HistoryCoordinator {
    private func handle(eventsFromHistoryPlaybackViewModel: HistoryMediaViewModeling) {
        DDLogDebug("handle(eventsFrom historyPlaybackViewModel")
        eventsFromHistoryPlaybackViewModel.drillInEvent.next { [unowned self] type in
            switch type {
            case .playable(let item):
                DDLogDebug(".defaultType: \(item)")
                self.goToPlayback(for: item)
            default:
                break
            }
        }.disposed(by: bag)
    }
    
    private func handle(eventsFromHistoryDownloadViewModel: HistoryMediaViewModeling) {
        DDLogDebug("handle(eventsFrom historyDownloadViewModel")
        eventsFromHistoryDownloadViewModel.drillInEvent.next { [unowned self] type in
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

