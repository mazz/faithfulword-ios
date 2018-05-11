import Foundation
import AVFoundation
import RxSwift
import RxCocoa

extension Reactive where Base: AVURLAsset {
    public var isPlayable: Observable<Bool> {
        return self.observe(Bool.self, #keyPath(AVURLAsset.isPlayable))
            .map { $0 ?? false }
    }
}
