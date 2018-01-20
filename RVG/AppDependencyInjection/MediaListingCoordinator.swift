import Foundation
import RxSwift
import RxCocoa

public final class MediaListingCoordinator {
    
    // MARK: Fields
    internal var playlistId: String?
    internal var mediaType: MediaType?
    
    private var mediaListingFlowCompletion: FlowCompletion!
    private let bag = DisposeBag()
    
    // MARK: Dependencies
    
    private let uiFactory: AppUIMaking
//    private let deviceManaging: DeviceManaging
    
    internal init(uiFactory: AppUIMaking) {
        self.uiFactory = uiFactory
//        self.deviceManaging = deviceManaging
    }
}

// MARK: <NavigationCoordinating>
extension MediaListingCoordinator: NavigationCoordinating {
    public func flow(with setup: FlowSetup, completion: @escaping FlowCompletion, context: FlowContext) {
        // 1. Hang on to the completion block for when the user if done with now-playing.
        mediaListingFlowCompletion = completion
        
        if let playlistId = playlistId, let mediaType = mediaType {
            let mediaListingViewController = self.uiFactory.makeMediaListing(playlistId: playlistId, mediaType: mediaType)
//            let mediaListingViewController = self.uiFactory.makeMediaListing(mediaId: mediaId, mediaType: mediaType)
            //            .makeDeviceNowPlayingFullScreen(for: deviceManaging.currentDevice.asObservable())
            setup(mediaListingViewController)
            handle(eventsFrom: mediaListingViewController.viewModel)
        }
    }
    
}

// MARK: Event handling for now playing screen.
extension MediaListingCoordinator {
    private func handle(eventsFrom mediaListingViewModel: MediaListingViewModel) {
        print("handle(eventsFrom mediaListingViewModel")
//        mediaListingViewModel.closeEvent.subscribe(onNext: { [unowned self] _ in
//            self.mediaListingFlowCompletion(.finished)
//        }).disposed(by: bag)
    }
}

