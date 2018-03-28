import Foundation
import UIKit
import RxSwift
import RxCocoa
import AlamofireImage

public final class DeviceNowPlayingBarView: UIView {

    // MARK: View elements
    
    @IBOutlet private weak var backgroundAlbumArtImageView: UIImageView!
    @IBOutlet private weak var thumbAlbumArtImageView: UIImageView!
    @IBOutlet private weak var trackTitleLabel: UILabel!
    @IBOutlet private weak var trackSubtitleLabel: UILabel!
    
    @IBOutlet private weak var skipPreviousButton: UIButton!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var skipNextButton: UIButton!
    
    // MARK: Fields
    
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var tapSubscription: Disposable?
    private var bag = DisposeBag()
    
    // MARK: Lifecycle & setup
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        reset()
        setupTapGesture()
    }
    
    private func setupTapGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer()
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: Public
    
    /// Set to true for view to be tappable.  Default is `false`.
    public var isTappable = false
    
    /// Bind the tap action to a given observer.
    /// Previous binding will be disposed.
    ///
    /// - Parameter observer: The observer to bind tap action to.
    public func bindTap(to observer: AnyObserver<UITapGestureRecognizer>) {
        tapSubscription?.dispose()
        tapSubscription = tapGestureRecognizer.rx.event.asObservable()
            .filter { [unowned self] _ in self.isTappable }
            .bind(to: observer)
    }
    
    /// Bind the view to a new view model.
    /// All previous bindings will be disposed.
    ///
    /// - Parameter viewModel: The view model to bind to.
    public func bind(to viewModel: DeviceNowPlayingViewModel) {
        // 1.  Reset to clear out previous subscriptions.
        reset()
        // 2.  Make new data bindings
        bindTrackInfo(from: viewModel)
        bindPlaybackActionState(from: viewModel)
        bindPlaybackActions(to: viewModel)
    }
    
    // MARK: Private
    
    private func reset() {
        bag = DisposeBag()
        tapSubscription?.dispose()
        backgroundAlbumArtImageView.image = nil
        thumbAlbumArtImageView.image = nil
        trackTitleLabel.text = nil
        trackSubtitleLabel.text = nil
        skipPreviousButton.isHidden = true
        skipNextButton.isHidden = true
    }
    
    private func bindTrackInfo(from viewModel: DeviceNowPlayingViewModel) {
//        viewModel.trackInfo.albumArtURL.asObservable()
//            .bind(to: backgroundAlbumArtImageView)
//            .disposed(by: bag)
//
//        viewModel.trackInfo.albumArtURL.asObservable()
//            .bind(to: thumbAlbumArtImageView)
//            .disposed(by: bag)
//
//        viewModel.trackInfo.title.asObservable()
//            .bind(to: trackTitleLabel.rx.text)
//            .disposed(by: bag)
//
//        viewModel.trackInfo.subtitle.asObservable()
//            .bind(to: trackSubtitleLabel.rx.text)
//            .disposed(by: bag)
    }
    
    private func bindPlaybackActionState(from viewModel: DeviceNowPlayingViewModel) {
//        viewModel.playback.isPlaying.asObservable()
//            .subscribe(onNext: { [unowned self] isPlaying in
//                let buttonTitle = isPlaying ? "||" : ">"
//                self.playPauseButton.setTitle(buttonTitle, for: .normal)
//            }).disposed(by: bag)
//
//        viewModel.playback.skipDisabled.asObservable()
//            .bind(to: skipNextButton.rx.isHidden)
//            .disposed(by: bag)
//
//        viewModel.playback.skipPreviousDisabled.asObservable()
//            .bind(to: skipPreviousButton.rx.isHidden)
//            .disposed(by: bag)
    }
    
    private func bindPlaybackActions(to viewModel: DeviceNowPlayingViewModel) {
//        skipPreviousButton.rx.tap
//            .bind(to: viewModel.playback.skipPreviousEvent)
//            .disposed(by: bag)
//
//        playPauseButton.rx.tap
//            .bind(to: viewModel.playback.playPauseEvent)
//            .disposed(by: bag)
//
//        skipNextButton.rx.tap
//            .bind(to: viewModel.playback.skipNextEvent)
//            .disposed(by: bag)
    }
    
}
