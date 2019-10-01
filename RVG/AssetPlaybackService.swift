import Foundation
import RxSwift
import AVFoundation
import MediaPlayer
//import RxAVFoundation

public protocol AssetPlaybackServicing {

    var assetPlaybackManager: AssetPlaybackManager { get }
    var playableItem: Field<Playable?> { get }
    var playables: Field<[Playable]> { get }

//    var playerItem: Observable<AVPlayerItem?> { get }
//    var player: AVPlayer { get }
//    internal var assetPlaybackManager: AssetPlaybackManager { get }

//    func play()
//    func togglePlayPause()
//    func stop()
//    func pause()

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
public final class AssetPlaybackService: AssetPlaybackServicing {
    // MARK: Fields
    private let bag = DisposeBag()

    public private(set) var playableItem = Field<Playable?>(nil)
    public private(set) var playables = Field<[Playable]>([])

    // MARK: Dependencies
    public let assetPlaybackManager: AssetPlaybackManager
    internal let remoteCommandManager: RemoteCommandManager
    private let reachability: RxClassicReachable
    private var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)


    init(assetPlaybackManager: AssetPlaybackManager,
                remoteCommandManager: RemoteCommandManager,
                reachability: RxClassicReachable) {
        self.reachability = reachability

        self.assetPlaybackManager = assetPlaybackManager
        self.remoteCommandManager = remoteCommandManager
        // default features true
        self.remoteCommandManager.activatePlaybackCommands(true)
        self.remoteCommandManager.toggleNextTrackCommand(true)
        self.remoteCommandManager.togglePreviousTrackCommand(true)
        self.remoteCommandManager.toggleChangePlaybackPositionCommand(true)
        // leave these off because there is not enough room on the lock screen
        self.remoteCommandManager.toggleSkipForwardCommand(false)
        self.remoteCommandManager.toggleSkipBackwardCommand(false)
        self.remoteCommandManager.toggleSeekForwardCommand(false)
        self.remoteCommandManager.toggleSeekBackwardCommand(false)
        self.remoteCommandManager.toggleLikeCommand(false)
        self.remoteCommandManager.toggleDislikeCommand(false)
        self.remoteCommandManager.toggleBookmarkCommand(false)

        // Set the AVAudioSession as active.  This is required so that your application becomes the "Now Playing" app.
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        }
        catch {
            DDLogDebug("An Error occured activating the audio session: \(error)")
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP,
                                                                                                 .duckOthers,
                                                                                                 .defaultToSpeaker])
            //            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .mixWithOthers, .defaultToSpeaker])
        } catch {
            DDLogDebug("AVAudioSession error: \(error)")
        }
    }
    
    private func reactToReachability() {
        reachability.startNotifier().asObservable()
            .map({ status -> String in
                
                var outStatus: String = "unknown"
                switch status {
                    
                case .unknown:
                    outStatus = "unknown"
                case .notReachable:
                    outStatus = "notReachable"
                case .reachable(ClassicReachability.ConnectionType.wwan):
                    outStatus = "reachableWwan"
                case .reachable(ClassicReachability.ConnectionType.ethernetOrWifi):
                    outStatus = "reachableEthernetOrWifi"
                    
                }
                return outStatus
            })
            .filter { $0 == "reachableEthernetOrWifi" }
            .filter { $0 == "reachableWwan"}
            .filter { $0 == "notReachable" }
            .take(1)
            .subscribe(onNext: { networkStatus in
                
                if networkStatus == "reachableWwan" {
                    self.networkStatus.value = .reachable(ClassicReachability.ConnectionType.wwan)
                } else if networkStatus == "reachableEthernetOrWifi" {
                    self.networkStatus.value = .reachable(ClassicReachability.ConnectionType.ethernetOrWifi)
                } else if networkStatus == "notReachable" {
                    self.networkStatus.value = .notReachable
                } else if networkStatus == "unknown" {
                    self.networkStatus.value = .unknown
                } else {
                    self.networkStatus.value = .unknown
                }
            }).disposed(by: bag)
    }
}
