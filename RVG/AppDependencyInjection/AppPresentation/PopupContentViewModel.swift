import Foundation
import AVFoundation
import RxSwift

public final class PopupContentViewModel {
    // MARK: Fields
    public let assetPlaybackService: AssetPlaybackServicing?
    
    init(assetPlaybackService: AssetPlaybackServicing) {
        self.assetPlaybackService = assetPlaybackService
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
