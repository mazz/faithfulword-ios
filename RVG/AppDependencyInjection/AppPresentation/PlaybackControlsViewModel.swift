import Foundation
import AVFoundation
import RxSwift

public final class PlaybackControlsViewModel {
    // MARK: Fields
    public let assetPlaybackService: AssetPlaybackServicing?
    private var bag = DisposeBag()

    // MARK: Playback action handling

    public var sliderScrubEvent = PublishSubject<Float>()
    public var repeatButtonTapEvent = PublishSubject<RepeatSetting>()

    init(assetPlaybackService: AssetPlaybackServicing) {
        self.assetPlaybackService = assetPlaybackService
        setupBindings()
    }

    func setupBindings() {
        sliderScrubEvent.asObservable()
            .subscribe(onNext: { [unowned self] scrubValue in
                DDLogDebug("scrubValue: \(scrubValue)")
                if let assetPlaybackService = self.assetPlaybackService {
                    let assetPlaybackManager = assetPlaybackService.assetPlaybackManager
                    assetPlaybackManager.seekTo(Double(scrubValue))
                }
            })
            .disposed(by: bag)

        repeatButtonTapEvent.asObservable()
            .subscribe({ currentSetting in
                DDLogDebug("currentSetting: \(currentSetting)")
                if let assetPlaybackService = self.assetPlaybackService,
                    let repeatSetting = currentSetting.element {
                    let assetPlaybackManager = assetPlaybackService.assetPlaybackManager
                    assetPlaybackManager.repeatState = repeatSetting
                }
            })
            .disposed(by: bag)
    }
}
