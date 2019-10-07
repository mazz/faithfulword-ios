import Foundation
import RxSwift
import AVFoundation
import MediaPlayer
//import RxAVFoundation

public protocol AssetPlaybackServicing {

    var assetPlaybackManager: AssetPlaybackManager { get }
    var playableItem: Field<Playable?> { get }
    var playables: Field<[Playable]> { get }
    
    func playPlayback() -> Single<Void>
    func pausePlayback() -> Single<Void>
    func togglePlayPause() -> Single<Void>
    func updatePlaybackRate(_ rate: Float) -> Single<Void>
    func nextTrack() -> Single<Void>
    func nextPlayableTrack() -> Single<Playable?>
    func previousTrack() -> Single<Void>
    func previousPlayableTrack() -> Single<Playable?>
    func seekTo(_ position: TimeInterval) -> Single<Void>

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
        
        reactToReachability()
    }
    
    public func playPlayback() -> Single<Void> {
        return Single.create { [weak self] single in
            self?.assetPlaybackManager.play()
            single(.success(()))
            return Disposables.create {}
        }
    }
    
    public func pausePlayback() -> Single<Void> {
        return Single.create { [weak self] single in
            self?.assetPlaybackManager.pause()
            
            single(.success(()))
            return Disposables.create {}
        }
    }
    
    public func togglePlayPause() -> Single<Void> {
        return Single.create { [weak self] single in
            self?.assetPlaybackManager.togglePlayPause()
            single(.success(()))
            return Disposables.create {}
        }
    }
    
    public func updatePlaybackRate(_ rate: Float) -> Single<Void> {
        return Single.create { [weak self] single in
            self?.assetPlaybackManager.playbackRate(rate)
            single(.success(()))
            return Disposables.create {}
        }
    }

    public func nextTrack() -> Single<Void> {
        return Single.create { [weak self] single in
            self?.assetPlaybackManager.nextTrack()
            single(.success(()))
            return Disposables.create {}
        }
    }

    public func nextPlayableTrack() -> Single<Playable?> {
        return Single.create { [weak self] single in
            var next: Playable?
            
            if let playingPlayable: Playable = self?.playableItem.value,
                let playables: [Playable] = self?.playables.value,
                let playableIndex = playables.firstIndex(where: { $0.uuid == playingPlayable.uuid }) {
                var idx = -1
                if playableIndex < playables.count - 1 {
                    idx = self?.indexOfClosestNextPlayableTrack(playingPlayable) ?? -1
                }
                if idx > -1 {
                    next = self?.playables.value[idx]
                }
            }

            single(.success(next))
            return Disposables.create {}
        }
    }

    public func previousTrack() -> Single<Void> {
        return Single.create { [weak self] single in
            self?.assetPlaybackManager.previousTrack()
            single(.success(()))
            return Disposables.create {}
        }
    }
    
    public func previousPlayableTrack() -> Single<Playable?> {
        return Single.create { [weak self] single in
            var previous: Playable?
            
            if let playingPlayable: Playable = self?.playableItem.value,
                let playableIndex = self?.playables.value.firstIndex(where: { $0.uuid == playingPlayable.uuid }) {
                var idx = -1
                if playableIndex > 0 {
                    idx = self?.indexOfClosestPreviousPlayableTrack(playingPlayable) ?? -1
                }
                if idx > -1 {
                    previous = self?.playables.value[idx]
                }
            }
            
            single(.success(previous))
            return Disposables.create {}
        }
    }
    
    public func seekTo(_ position: TimeInterval) -> Single<Void> {
        return Single.create { [weak self] single in
            self?.assetPlaybackManager.seekTo(position)
            single(.success(()))
            return Disposables.create {}
        }
    }
    
    // assumes the playable is in the current list
    private func indexOfClosestPreviousPlayableTrack(_ playable: Playable) -> Int {
        var index: Int = -1
        guard let playableIndex = self.playables.value.firstIndex(where: { $0.uuid == playable.uuid }) else { return -1 }


        switch networkStatus.value {
        case .unknown:
            index = _indexOfClosestPreviousPlayableWithLocalFile(playable)
        case .notReachable:
            index = _indexOfClosestPreviousPlayableWithLocalFile(playable)
        case .reachable(_):
            index = playableIndex - 1
        }
        return index
    }
    
    private func _indexOfClosestPreviousPlayableWithLocalFile(_ playable: Playable) -> Int {
        var index: Int = -1
        guard let playableIndex = self.playables.value.firstIndex(where: { $0.uuid == playable.uuid }) else { return -1 }
        // slice the subarray before playable
        let slice = playables.value[0..<playableIndex]
        // cast slice to Array
        let prev = Array(slice)
        // find the last playable with a local file in the subarray
        if let localFileIndex: Int = prev.lastIndex(where: { $0.hasLocalFile() }) {
            index = localFileIndex
        }
        
        return index
    }

    // assumes the playable is in the current list
    private func indexOfClosestNextPlayableTrack(_ playable: Playable) -> Int {
        var index: Int = -1
        guard let playableIndex = self.playables.value.firstIndex(where: { $0.uuid == playable.uuid }) else { return -1 }
        
        
        switch networkStatus.value {
        case .unknown:
            index = _indexOfClosestNextPlayableWithLocalFile(playable)
        case .notReachable:
            index = _indexOfClosestNextPlayableWithLocalFile(playable)
        case .reachable(_):
            index = playableIndex + 1
        }
        return index
    }

    private func _indexOfClosestNextPlayableWithLocalFile(_ playable: Playable) -> Int {
        var index: Int = -1
        guard let playableIndex = self.playables.value.firstIndex(where: { $0.uuid == playable.uuid }) else { return -1 }
        // slice the subarray after playable
        
        
//        let slice = playables.value.dropFirst(playableIndex + 1)
        let slice = playables.value[playableIndex + 1..<playables.value.count]
        // cast slice to Array
        let next = Array(slice)
        // find the last playable with a local file in the subarray
//        if let localFileIndex: Int = next.firstIndex(where: { playable -> Bool in
//            var found: Bool = false
//            if playable.hasLocalFile() {
//                found = true
//            }
//            return found
//        }) {
//
//        }
        var foundLocalPlayable: Playable? = nil
        if let localFileIndex: Int = next.firstIndex(where: { $0.hasLocalFile() }) {
            index = localFileIndex
            foundLocalPlayable = next[localFileIndex]
        }
        
        if let found: Playable = foundLocalPlayable,
            let localPlayableIndex = self.playables.value.firstIndex(where: { $0.uuid == found.uuid }) {
            index = localPlayableIndex
        } else {
            index = -1
        }
        
        return index
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
//            .filter { $0 == "reachableEthernetOrWifi" }
//            .filter { $0 == "reachableWwan"}
//            .filter { $0 == "notReachable" }
//            .take(1)
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

extension Playable {
    func hasLocalFile() -> Bool {
        var found: Bool = false
        guard let path: String = self.path,
            let percentEncoded: String = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let prodUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(percentEncoded))
            else { return false }
        
        let url: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(self.uuid.appending(String(describing: ".\(prodUrl.pathExtension)"))).path)
        found = FileManager.default.fileExists(atPath: url.path)
        return found
    }
}
