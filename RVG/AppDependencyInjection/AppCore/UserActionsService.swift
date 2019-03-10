import Foundation
import RxSwift

protocol UserActionsServicing {
    func updatePlaybackPosition(playable: Playable, position: Float) -> Single<Void>
    func fetchPlaybackPosition(playable: Playable) -> Single<Double>
}

public final class UserActionsService: UserActionsServicing {
    
    // MARK: Dependencies
    private let dataService: UserActionsDataServicing
    
    public init(dataService: UserActionsDataServicing) {
        self.dataService = dataService
    }
    
    public func updatePlaybackPosition(playable: Playable, position: Float) -> Single<Void> {
        return dataService.updatePlaybackPosition(playable: playable, position: position)
            .do(onSuccess: { _ in
                DDLogDebug("playback position updated")
            })
    }
    
    public func fetchPlaybackPosition(playable: Playable) -> Single<Double> {
        return dataService.fetchPlaybackPosition(playable: playable)
            .do(onSuccess: { position in
                DDLogDebug("position: \(position)")
                //                self.userLanguage.value = identifier
            })
    }
}
