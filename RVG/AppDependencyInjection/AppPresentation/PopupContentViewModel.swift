import Foundation
import AVFoundation
import RxSwift

public final class PopupContentViewModel {
    // MARK: Fields
    public let assetPlaybackService: AssetPlaybackServicing?
    private var bag = DisposeBag()

    // MARK: Playback action handling

    public var sliderScrubEvent = PublishSubject<Float>()

    init(assetPlaybackService: AssetPlaybackServicing) {
        self.assetPlaybackService = assetPlaybackService
        setupBindings()
    }

    func setupBindings() {
        sliderScrubEvent.asObservable()
            .subscribe(onNext: { [unowned self] scrubValue in
                print("scrubValue: \(scrubValue)")
                if let assetPlaybackService = self.assetPlaybackService {
                    let assetPlaybackManager = assetPlaybackService.assetPlaybackManager
                    assetPlaybackManager.seekTo(Double(scrubValue))
                }
            })
            .disposed(by: self.bag)
//            .filterNils()
//            .subscribe(

//        urlAsset.asObservable()
//            .filterNils()
//            .subscribe(onNext: { urlAsset in
//            print("url asset: \(urlAsset)")
//        }, onError: { error in
//            print("url asset error: \(error)")
//        }, onCompleted: {
//
//        }).disposed(by: self.bag)
    }
}
