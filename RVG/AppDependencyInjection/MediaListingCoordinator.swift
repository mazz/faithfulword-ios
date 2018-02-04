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
            handle(eventsFrom: mediaListingViewController.viewModel)
        }
    }
    
    func goToPlayback(for playable: Playable) {
        print("goToPlayback playable: \(playable)")
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

