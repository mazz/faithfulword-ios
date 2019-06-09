import Foundation
import RxSwift

internal final class ChannelCoordinator {
    // MARK: Dependencies

    private let uiFactory: AppUIMaking
    private let resettableMediaListingCoordinator: Resettable<MediaListingCoordinator>

    // MARK: Fields
//    internal var categoryType: CategoryListingType?
    internal var mainNavigationController: UINavigationController!
    internal var channelUuid: String?
    private let bag = DisposeBag()
    private var channelFlowCompletion: FlowCompletion!

    internal init(uiFactory: AppUIMaking,
                  resettableMediaListingCoordinator: Resettable<MediaListingCoordinator>
        ) {
        self.uiFactory = uiFactory
        self.resettableMediaListingCoordinator = resettableMediaListingCoordinator
    }
}

extension ChannelCoordinator: NavigationCoordinating {
    public func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        var channelViewController: ChannelViewController!
        
        if let channelUuid: String = self.channelUuid {
            DDLogDebug("channelUuid: \(channelUuid)")
            
            channelViewController = uiFactory.makeChannel(channelUuid: channelUuid)
//            attachRootMenuAction(to: channelViewController)
//            attachSettingAction(to: channelViewController)
            
//            mainNavigationController = UINavigationController(rootViewController: channelViewController)
        } else {
            DDLogError("⚠️ fatal error, need a Bible Channel! Bailing!")
            completion(FlowCompletionType.error)
        }
        
        handle(eventsFrom: channelViewController.viewModel)
//        setup(mainNavigationController)
        setup(channelViewController)
        channelFlowCompletion = completion
    }

    private func goToPlaylist(for playlistUuid: String) {
        DDLogDebug("goToPlaylist: \(playlistUuid)")
        // do not use a new flow, because Chapters is part of the Book flow AFAICT
        //        self.resettableSplashScreenCoordinator.value.flow(with: { viewController in
        
        self.resettableMediaListingCoordinator.value.playlistId = playlistUuid
        self.resettableMediaListingCoordinator.value.mediaType = .audioChapter
        self.resettableMediaListingCoordinator.value.flow(with: { viewController in
            
        self.mainNavigationController.pushViewController(viewController, animated: true)
//        self.mainNavigationController.present(viewController, animated: true)
        }, completion: { _ in
            self.mainNavigationController.dismiss(animated: true)
            self.resettableMediaListingCoordinator.reset()
            //            self.resettableSplashScreenCoordinator.reset()
            
        }, context: .push(onto: self.mainNavigationController))
    }
//    func goToCategory(for categorizable: Categorizable) {
//        DispatchQueue.main.async {
//            DDLogDebug("goToCategory categorizable: \(categorizable)")
//            self.resettableMediaListingCoordinator.value.playlistId = categorizable.categoryUuid
//            self.resettableMediaListingCoordinator.value.mediaType = (categorizable is Gospel) ? .audioGospel : .audioMusic
////                : (categorizable is Music)
////                ? .audioMusic : .audioSermon
//            self.resettableMediaListingCoordinator.value.flow(with: { viewController in
//
//                self.mainNavigationController.pushViewController(
//                    viewController,
//                    animated: true
//                )
//                //            self.mainNavigationController.present(viewController, animated: true)
//            }, completion: { _ in
//                self.mainNavigationController.dismiss(animated: true)
//                self.resettableMediaListingCoordinator.reset()
//                //            self.resettableSplashScreenCoordinator.reset()
//
//            }, context: .push(onto: self.mainNavigationController))
//        }
//    }
}

// MARK: Event handling for medialisting screen
extension ChannelCoordinator {
    private func handle(eventsFrom mainViewModel: PlaylistViewModel) {
        mainViewModel.drillInEvent.next { [unowned self] type in
            switch type {
                
            case .playlistItemType(let item):
                DDLogDebug("handle event: \(item)")
                self.goToPlaylist(for: item.uuid)
            }
        }
    }
}
