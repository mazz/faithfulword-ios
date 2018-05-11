import Foundation
import AVFoundation
import RxSwift

public final class DemoMusicPlayerViewModel {
    public var urlAsset = Field<AVURLAsset?>(nil)

    private let bag = DisposeBag()

//    private let assetPlaybackService: AssetPlaybackService
    init(
//        assetPlaybackService: AssetPlaybackService
        ) {
//        self.assetPlaybackService = assetPlaybackService

//        setupBindings()
    }

//    func setupBindings() {
//
//        urlAsset.asObservable()
//            .filterNils()
//            .subscribe(onNext: { urlAsset in
//            print("url asset: \(urlAsset)")
//        }, onError: { error in
//            print("url asset error: \(error)")
//        }, onCompleted: {
//
//        }).disposed(by: self.bag)
//    }
}
