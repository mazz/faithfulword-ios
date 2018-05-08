import Foundation
import RxSwift
import AVFoundation
import MediaPlayer

public protocol AssetPlaybackServicing {

    var player: AVPlayer { get }
//    var asset: Asset? { get }
//    var asset: Field<Asset?> { get }

    func play()
    func togglePlayPause()
    func stop()
    func pause()

//    var asset: Asset { get }

//    // Current authentication state
//    var authState: Observable<AuthStatus> { get }
//    // Current user
//    var currentUser: ApplicationUser? { get }
//    // Current user's music service accounts
//    //    var musicServiceAccounts: Observable<[MusicServiceAccount]> { get }
//
//    func start()
//    func logout()
//
//    func startLoginFlow() -> Single<Void>
//    //    func startLoginFlow(over viewController: UIViewController) -> Single<Void>
//    //    func startRegistrationFlow(over viewController: UIViewController) -> Single<Void>
//    //    func startUpdateFlow(over viewController: UIViewController)
//
//    //    func fetchMusicServiceAccounts() -> Observable<[MusicServiceAccount]>
}

/// Manages all account related things
public final class AssetPlaybackService: NSObject {

    /// Notification that is posted when the `nextTrack()` is called.
    static let nextTrackNotification = Notification.Name("nextTrackNotification")

    /// Notification that is posted when the `previousTrack()` is called.
    static let previousTrackNotification = Notification.Name("previousTrackNotification")

    /// An enumeration of possible playback states that `AssetPlaybackService` can be in.
    ///
    /// - initial: The playback state that `AssetPlaybackService` starts in when nothing is playing.
    /// - playing: The playback state that `AssetPlaybackService` is in when its `AVPlayer` has a `rate` != 0.
    /// - paused: The playback state that `AssetPlaybackService` is in when its `AVPlayer` has a `rate` == 0.
    /// - interrupted: The playback state that `AssetPlaybackService` is in when audio is interrupted.
    enum playbackState {
        case initial, playing, paused, interrupted
    }

    static let currentAssetDidChangeNotification = Notification.Name("currentAssetDidChangeNotification")

    /// Notification that is posted when the internal AVPlayer rate did change.
    static let playerRateDidChangeNotification = Notification.Name("playerRateDidChangeNotification")

    // MARK: Fields

//    public var asset = Field<Asset?>(nil)
    public var player: AVPlayer = AVPlayer()

    /// The instance of `MPNowPlayingInfoCenter` that is used for updating metadata for the currently playing `Asset`.
    fileprivate let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()

    /// A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)` method.
    private var timeObserverToken: Any?

    /// The progress in percent for the playback of `asset`.  This is marked as `dynamic` so that this property can be observed using KVO.
    @objc dynamic var percentProgress: Float = 0

    /// The total duration in seconds for the `asset`.  This is marked as `dynamic` so that this property can be observed using KVO.
    @objc dynamic var duration: Float = 0

    /// The current playback position in seconds for the `asset`.  This is marked as `dynamic` so that this property can be observed using KVO.
    @objc dynamic var playbackPosition: Float = 0

    var state: AssetPlaybackService.playbackState = .initial

    /// A Bool for tracking if playback should be resumed after an interruption.  See README.md for more information.
    private var shouldResumePlaybackAfterInterruption = true

    /// The AVPlayerItem associated with AssetPlaybackManager.asset.urlAsset
    fileprivate var playerItem: AVPlayerItem! {
        willSet {
            if playerItem != nil {
                playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil)
                NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            }
        }
        didSet {
            if playerItem != nil {
                playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.initial, .new], context: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(AssetPlaybackService.handleAVPlayerItemDidPlayToEndTimeNotification(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            }
        }
    }

    /// The Asset that is currently being loaded for playback.
    public var asset: Asset! {
        willSet(newValue) {
            print("asset newValue willSet : \(newValue)")
            if asset != nil {
                asset.urlAsset.removeObserver(self, forKeyPath: #keyPath(AVURLAsset.isPlayable), context: nil)
            }
        }
        //        set {
        //            asset = asset
        //        }
        didSet(newValue) {
            print("asset newValue didSet: \(newValue)")
            if asset != nil {
                asset.urlAsset.addObserver(self, forKeyPath: #keyPath(AVURLAsset.isPlayable), options: [.initial, .new], context: nil)
            }
            else {
                // Unload currentItem so that the state is updated globally.
                player.replaceCurrentItem(with: nil)
            }

            NotificationCenter.default.post(name: AssetPlaybackService.currentAssetDidChangeNotification, object: nil)
        }
    }

//    private let bag = DisposeBag()

    // MARK: Dependencies

    public override init(
        ) {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(AssetPlaybackService.handleAudioSessionInterruption(notification:)), name: .AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())

        // Add the Key-Value Observers needed to keep internal state of `AssetPlaybackManager` and `MPNowPlayingInfoCenter` in sync.
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem), options: [.initial, .new], context: nil)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: [.new], context: nil)

        // Add a periodic time observer to keep `percentProgress` and `playbackPosition` up to date.
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1.0 / 60.0, Int32(NSEC_PER_SEC)), queue: DispatchQueue.main, using: { [weak self] time in
            let timeElapsed = Float(CMTimeGetSeconds(time))
            guard let duration = self?.player.currentItem?.duration else { return }

            let durationInSecods = Float(CMTimeGetSeconds(duration))

            self?.playbackPosition = timeElapsed
            self?.percentProgress = timeElapsed / durationInSecods
        })
    }

    deinit {
        // Remove all KVO and notification observers.

        NotificationCenter.default.removeObserver(self, name: .AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())

        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem), context: nil)
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate), context: nil)

        // Remove the periodic time observer.
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }

    // MARK: Helpers

    //    private func fetchAccountInfo() {
    //        dataService.fetchAccountInfo().subscribe(onSuccess: { [unowned self] accountInfo in
    //            print("Cached Login Flow - Retrieved Passport Account Info: \(accountInfo)")
    //            self.currentUser?.accountInfo = accountInfo
    //            self.authStateBehaviorSubject.onNext(.accountInfoRetrieved)
    //        }).disposed(by: bag)
    //    }

    // MARK: Notification Observing Methods

    @objc func handleAVPlayerItemDidPlayToEndTimeNotification(notification: Notification) {
        player.replaceCurrentItem(with: nil)
    }

    @objc func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo, let typeInt = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSessionInterruptionType(rawValue: typeInt) else { return }

        switch interruptionType {
        case .began:
            state = .interrupted
        case .ended:
            do {
                try AVAudioSession.sharedInstance().setActive(true, with: [])

                if shouldResumePlaybackAfterInterruption == false {
                    shouldResumePlaybackAfterInterruption = true

                    return
                }

                guard let optionsInt = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }

                let interruptionOptions = AVAudioSessionInterruptionOptions(rawValue: optionsInt)

                if interruptionOptions.contains(.shouldResume) {
                    play()
                }
            }
            catch {
                print("An Error occured activating the audio session while resuming from interruption: \(error)")
            }
        }
    }

    // MARK: Key-Value Observing Method

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVURLAsset.isPlayable) {
            if asset.urlAsset.isPlayable {
                playerItem = AVPlayerItem(asset: asset.urlAsset)
                player.replaceCurrentItem(with: playerItem)
            }
        }
        else if keyPath == #keyPath(AVPlayerItem.status) {
            if playerItem.status == .readyToPlay {
                player.play()
            }
        }
        else if keyPath == #keyPath(AVPlayer.currentItem){

            // Cleanup if needed.
            if player.currentItem == nil {
                asset = nil
                playerItem = nil
            }

            updateGeneralMetadata()
        }
        else if keyPath == #keyPath(AVPlayer.rate) {
            updatePlaybackRateMetadata()
            NotificationCenter.default.post(name: AssetPlaybackService.playerRateDidChangeNotification, object: nil)
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // MARK: MPNowPlayingInforCenter Management Methods

    func updateGeneralMetadata() {
        guard player.currentItem != nil, let urlAsset = player.currentItem?.asset else {
            nowPlayingInfoCenter.nowPlayingInfo = nil

            #if os(macOS)
                nowPlayingInfoCenter.playbackState = .stopped
            #endif

            return
        }

        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        let title = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyTitle, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? asset.assetName
        let album = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyAlbumName, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? "Unknown"
        let artworkData = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common).first?.value as? Data ?? Data()


        #if os(macOS)
            let image = NSImage(data: artworkData) ?? NSImage()
            let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { (_) -> NSImage in
                return image
            })
        #else
            let image = UIImage(data: artworkData) ?? UIImage()
            let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
                return image
            })
        #endif

        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    func updatePlaybackRateMetadata() {
        guard player.currentItem != nil else {
            duration = 0
            nowPlayingInfoCenter.nowPlayingInfo = nil

            return
        }

        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        duration = Float(CMTimeGetSeconds(player.currentItem!.duration))
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(player.currentItem!.currentTime())
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = player.rate

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo

        if player.rate == 0.0 {
            state = .paused

            #if os(macOS)
                nowPlayingInfoCenter.playbackState = .paused
            #endif
        }
        else {
            state = .playing

            #if os(macOS)
                nowPlayingInfoCenter.playbackState = .playing
            #endif
        }

    }

}

extension AssetPlaybackService: AssetPlaybackServicing {

    // MARK: Playback Control Methods.

    public func play() {
        guard asset != nil else { return }

        if shouldResumePlaybackAfterInterruption == false {
            shouldResumePlaybackAfterInterruption = true

            return
        }

        player.play()
    }

    public func pause() {
        guard asset != nil else { return }

        if state == .interrupted {
            shouldResumePlaybackAfterInterruption = false

            return
        }

        player.pause()
    }

    public func togglePlayPause() {
        guard asset != nil else { return }

        if player.rate == 1.0 {
            pause()
        }
        else {
            play()
        }
    }

    public func stop() {
        guard asset != nil else { return }

        asset = nil
        playerItem = nil
        player.replaceCurrentItem(with: nil)
    }

    func previousTrack() {
        guard asset != nil else { return }

        NotificationCenter.default.post(name: AssetPlaybackService.previousTrackNotification, object: nil, userInfo: [Asset.nameKey: asset.assetName])
    }


}
