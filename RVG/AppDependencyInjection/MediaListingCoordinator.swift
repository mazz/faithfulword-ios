import Foundation
import RxSwift
import RxCocoa

public final class MediaListingCoordinator {
    
    // MARK: Fields
    
    private var trackListingFlowCompletion: FlowCompletion!
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
        trackListingFlowCompletion = completion
        // 2. Create a full-screen now-playing view controller and show to user.
        let trackListingViewController = self.uiFactory.makeMediaListing()
//            .makeDeviceNowPlayingFullScreen(for: deviceManaging.currentDevice.asObservable())
        setup(trackListingViewController)
        handle(eventsFrom: trackListingViewController.viewModel)
    }
    
}

// MARK: Event handling for now playing screen.
extension MediaListingCoordinator {
    private func handle(eventsFrom trackListingViewModel: MediaListingViewModel) {
        print("handle(eventsFrom trackListingViewModel")
//        trackListingViewModel.closeEvent.subscribe(onNext: { [unowned self] _ in
//            self.trackListingFlowCompletion(.finished)
//        }).disposed(by: bag)
    }
}

