import Foundation
import RxSwift

public final class DeviceNowPlayingViewModel {
    
    // MARK: Now playing info
    
//    public let trackInfo: DeviceTrackInfoViewModel
//    public let playback: DevicePlayTrackViewModel
//    public let options: DevicePlayOptionsViewModel
//    public let volume: DeviceVolumeViewModel

    // MARK: Event handling
    
    public let closeEvent = PublishSubject<Void>()
    
    // MARK: Fields
    
//    private var device: DeviceProtocol?
    private let viewModelLifetimeBag = DisposeBag()
    private var deviceSubscriptionsBag = DisposeBag()
    
    // MARK: Dependencies & instantiation
    
    public init(//deviceStream: Observable<DeviceProtocol?>,
                appForegroundStream: Observable<Void>) {
//        trackInfo = DeviceTrackInfoViewModel(deviceStream: deviceStream)
//        playback = DevicePlayTrackViewModel(deviceStream: deviceStream)
//        options = DevicePlayOptionsViewModel(deviceStream: deviceStream)
//        volume = DeviceVolumeViewModel(deviceStream: deviceStream)

//        deviceStream
//            .next { [unowned self] device in
//                // 1. Clear out all existing subscriptions to device
////                self.deviceSubscriptionsBag = DisposeBag()
//                // 2. Update device
////                self.device = device
//                // 3. Fetch info for latest device
////                device?.execute(FetchNowPlaying()).subscribeAndDispose(by: self.deviceSubscriptionsBag)
////                device?.execute(FetchVolume()).subscribeAndDispose(by: self.deviceSubscriptionsBag)
//            }
//            .disposed(by: viewModelLifetimeBag)
        
        appForegroundStream
            .next { [unowned self] in
//                self.device?.execute(FetchNowPlaying()).subscribeAndDispose(by: self.deviceSubscriptionsBag)
//                self.device?.execute(FetchVolume()).subscribeAndDispose(by: self.deviceSubscriptionsBag)
            }
            .disposed(by: viewModelLifetimeBag)
    }
    
}
