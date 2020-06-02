import Foundation
import AVFoundation
import RxSwift
import os.log

public final class PlaybackControlsViewModel {
    // MARK: Fields
    public var assetPlaybackService: AssetPlaybackServicing
    private let historyService: HistoryServicing
    private let reachability: RxClassicReachable
    private var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)

    private var bag = DisposeBag()
    // MARK: from client
    public private(set) var sliderScrubEvent = PublishSubject<Float>()
    public private(set) var repeatButtonTapEvent = PublishSubject<RepeatSetting>()
    // MARK: to client
    public private(set) var songTitle = Field<NSAttributedString>(NSAttributedString(string: "--", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.songTitleFont()]))
    public private(set) var artistName = Field<NSAttributedString>(NSAttributedString(string: "--", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.0/255.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), NSAttributedString.Key.font: UIFont.artistNameFont()]))
    public private(set) var albumArt = Field<UIImage?>(nil)
    
    public private(set) var playbackPlayable = Field<Playable?>(nil)
    public private(set) var playbackState = Field<AssetPlaybackManager.playbackState>(.initial)
    public private(set) var playDisabled = Field<Bool>(false)

    // MARK: internal use for synchronization
    public var selectedPlayable = Field<Playable?>(nil)

//    public private(set) var estimatedPlaybackPosition = Field<Float>(Float(0))
//    public private(set) var estimatedDuration = Field<Float>(Float(0))
    
    // MARK: --
    
    init(assetPlaybackService: AssetPlaybackServicing,
         historyService: HistoryServicing,
         reachability: RxClassicReachable) {
        self.assetPlaybackService = assetPlaybackService
        self.historyService = historyService
        self.reachability = reachability
        
        // Add the notification observers needed to respond to events from the `AssetPlaybackManager`.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handleCurrentAssetDidChangeNotification(notification:)), name: AssetPlaybackManager.currentAssetDidChangeNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handleRemoteCommandNextTrackNotification(notification:)), name: AssetPlaybackManager.nextTrackNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handleRemoteCommandPreviousTrackNotification(notification:)), name: AssetPlaybackManager.previousTrackNotification, object: nil)
//        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handlePlayerRateDidChangeNotification(notification:)), name: AssetPlaybackManager.playerRateDidChangeNotification, object: nil)
//        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handlePlayerDidPlayNotification(notification:)), name: AssetPlaybackManager.playerIsPlayingNotification, object: nil)
//        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handleAVPlayerItemDidPlayToEndTimeNotification(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        reactToReachability()
        setupBindings()
    }
    
    func setupBindings() {
        
        // user scrubs, we manually seek
        sliderScrubEvent.asObservable()
            .subscribe(onNext: { [unowned self] scrubValue in
                DDLogDebug("scrubValue: \(scrubValue)")
                //                if let assetPlaybackService = self.assetPlaybackService {
                //                if let assetPlaybackManager = self.assetPlaybackService.assetPlaybackManager {
                self.seekTo(Double(scrubValue))
                //                }
            })
            .disposed(by: bag)
        
        // user hits repeat, we change repeat state
        repeatButtonTapEvent.asObservable()
            .subscribe({ [unowned self] currentSetting in
                DDLogDebug("currentSetting: \(currentSetting)")
                //                if let assetPlaybackService = self.assetPlaybackService,
                if let repeatSetting = currentSetting.element {
                    //                        let assetPlaybackManager = self.assetPlaybackService.assetPlaybackManager
                    self.assetPlaybackService.assetPlaybackManager.repeatState = repeatSetting
                }
            })
            .disposed(by: bag)
        
        // when network status changes, check if there is a file URL for this playable
        // if we are offline and no file, it's not playable so disable the play button
        
        networkStatus.asObservable()
            .next { [unowned self] networkStatus in
                
                let fileExists: Bool = self.playableHasLocalFile()
                switch networkStatus {
                    
                case .unknown:
                    self.pausePlayback()
                    self.playDisabled.value = false
                case .notReachable:
                    if !fileExists {
                        self.pausePlayback()
                    }
                    self.playDisabled.value = !fileExists
                case .reachable(_):
//                    self.assetPlaybackService.assetPlaybackManager.play()
                    self.playDisabled.value = false
                }
                
            }
            .disposed(by: bag)
        
        selectedPlayable.asObservable()
            .filterNils()
            .next { [unowned self] selectedPlayable in
                DDLogDebug("selectedPlayable: \(selectedPlayable)")
                self.historyService.fetchLastUserActionPlayableState(for: selectedPlayable.uuid)
                    .asObservable()
                    .next({ [unowned self] historyPlayable in
                        // if the history item is not nil, assign it to playbackPlayable
                        // which will be observed by the view controller
                        // if the history item IS nil, assign selectedPlayable to playbackPlayable
                        if let _ = historyPlayable {
                            DDLogDebug("historyPlayable: \(String(describing: historyPlayable))")
                            self.playbackPlayable.value = historyPlayable
//                            self.assetPlaybackService.assetPlaybackManager.seekTo(Double(historyPlayable.playbackPosition))
                        } else {
                            self.playbackPlayable.value = self.selectedPlayable.value
                        }
                    })
                    .disposed(by: self.bag)
            }
            .disposed(by: bag)
        
        assetPlaybackService.playerStateChange
            .asObservable()
//            .distinctUntilChanged()
            .subscribe(onNext: { (state) in
                os_log("playbackstate: %@", log: OSLog.data, String(describing: state))
                self.playbackState.value = state

            }).disposed(by: bag)
    }
    
    func shouldAutoStartPlayback(should: Bool) {
        self.assetPlaybackService.shouldAutostart = should
    }
    
    func playPlayback() {
        assetPlaybackService.playPlayback()
            .asObservable()
            .subscribeAndDispose(by: bag)
    }

    func pausePlayback() {
        assetPlaybackService.pausePlayback()
            .asObservable()
            .subscribeAndDispose(by: bag)
    }

    func togglePlayPause() {
        assetPlaybackService.togglePlayPause()
            .asObservable()
            .subscribeAndDispose(by: bag)
    }
    
    func seekTo(_ position: TimeInterval) {
        assetPlaybackService.seekTo(position)
            .asObservable()
            .subscribeAndDispose(by: bag)
    }

    func updatePlaybackRate(_ rate: Float) {
        assetPlaybackService.updatePlaybackRate(rate)
            .asObservable()
            .subscribeAndDispose(by: bag)
    }

    func nextTrack() {
        assetPlaybackService.nextTrack()
            .asObservable()
            .subscribeAndDispose(by: bag)
    }

    // returns the next Playable track i.e. if the
    // user is offline, will return the next Playable
    // in the current playlist that has been downloaded
    // if the user is online, it will be the next ordinal track
    
    func nextPlayableTrack() -> Single<Playable?> {
        return assetPlaybackService.nextPlayableTrack()
//            .asObservable()
//            .subscribeAndDispose(by: bag)
    }

    func previousTrack() {
        return assetPlaybackService.previousTrack()
            .asObservable()
            .subscribeAndDispose(by: bag)
    }

    // returns the previous Playable track i.e. if the
    // user is offline, will return the previous Playable
    // in the current playlist that has been downloaded
    // if the user is online, it will be the previous ordinal track

    func previousPlayableTrack() -> Single<Playable?> {
        return assetPlaybackService.previousPlayableTrack()
//            .asObservable()
//            .subscribeAndDispose(by: bag)
    }
    
    // MARK: Notification Observer Methods
    
    /// events should happen in this sequence:
    /// - user taps |< or >| and handleRemoteCommandNextTrackNotification or handleRemoteCommandPreviousTrackNotification fires
    /// - PlaybackControlsViewModel.selectedPlayable changes
    /// - database is queried to determine if the user played selectedPlayable before
    ///     - true, the historyPlayable is assigned to playbackPlayable
    ///     - false, then selectedPlayable is assigned to playbackPlayable
    /// - PlaybackControlsViewModel.playbackPlayable changes
    /// - PopupContentController observable playbackViewModel.playbackPlayable subscriber fires
    /// - PopupContentController.playbackAsset is created and set on assetPlaybackManager
    /// - AssetPlaybackManager calls .play() on internal playerItem
    /// - handleCurrentAssetDidChangeNotification gets fired
    /// - UserActionsViewModel will store playback position every 1.5 seconds. NOTE: MUST use the selectedPlayable
    ///   - or, Playable, as the state to track. IF we use a UserActionPlayable to track, the Playable.uuid and
    ///   - the UserActionPlayable.playableUuid get all mixed-together and duplicate db entries occur, resulting
    ///   - in a bug where playbackPosition is stored as the correct value in one entry and 0.0 in a `fake` entry

    @objc func handleCurrentAssetDidChangeNotification(notification: Notification) {
        DDLogDebug("PlaybackControlsViewModel handleCurrentAssetDidChangeNotification notification: \(notification)")
        
        if self.assetPlaybackService.assetPlaybackManager.asset != nil {
            songTitle.value = NSAttributedString(string: self.assetPlaybackService.assetPlaybackManager.asset.name, attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.songTitleFont()])
            
            artistName.value = NSAttributedString(string: self.assetPlaybackService.assetPlaybackManager.asset.artist, attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.0/255.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), NSAttributedString.Key.font: UIFont.artistNameFont()])
            
            guard let asset = self.assetPlaybackService.assetPlaybackManager.asset else {
                return
            }
            
            let urlAsset = asset.urlAsset
            DDLogDebug("urlAsset: \(urlAsset)")
            let artworkData = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common).first?.value as? Data ?? Data()
            
            if let image = UIImage(data: artworkData) {
                albumArt.value = image
            } else {
                if let image = UIImage(named: "creation") {
                    albumArt.value = image
                } else {
                    albumArt.value = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
                }
            }
        }
        else {
            albumArt.value = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
            songTitle.value = NSAttributedString(string: "--", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black,NSAttributedString.Key.font: UIFont.songTitleFont()])
            
            artistName.value = NSAttributedString(string: "--", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.0/255.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), NSAttributedString.Key.font: UIFont.artistNameFont()])
        }
        
        // set playback state to update play button etc
//        playbackState.value = assetPlaybackService.assetPlaybackManager.state
        
        // might disable play button if we are offline and there is no local file
        let fileExists: Bool = playableHasLocalFile()
        
        switch self.networkStatus.value {
            
        case .unknown:
            self.pausePlayback()
            self.playDisabled.value = false
        case .notReachable:
            if !fileExists {
                self.pausePlayback()
            }
            self.playDisabled.value = !fileExists
        case .reachable(_):
//            self.assetPlaybackService.assetPlaybackManager.play()
            self.playDisabled.value = false
        }
    }
    
    @objc func handleRemoteCommandNextTrackNotification(notification: Notification) {
        DDLogDebug("handleRemoteCommandNextTrackNotification notification: \(notification)")
        
        let playables: [Playable] = assetPlaybackService.playables.value
        
        guard let assetUuid = notification.userInfo?[Asset.uuidKey] as? String else { return }
        guard let assetIndex = playables.firstIndex(where: { $0.uuid == assetUuid }) else { return }

        
//        if let assetIndex = playables.index(where: { $0.uuid == assetUuid }) {
        DDLogDebug("assetIndex: \(assetIndex)")
            
            //        let playableUuidIndex = playables.index(where: { $0.playableUuid == assetUuid })
            
            //        if assetIndex < playables.count - 1 { self.playbackPlayable.value = playables[assetIndex + 1] }
        if assetIndex < playables.count - 1 {
            self.nextPlayableTrack()
                .subscribe(onSuccess: { [weak self] nextPlayable in
                    if let _ = nextPlayable {
                        self?.pausePlayback()
                        self?.assetPlaybackService.playableItem.value = nextPlayable
                        self?.selectedPlayable.value = self?.assetPlaybackService.playableItem.value
                    }
                }) { error in
                DDLogDebug("error: \(error)")
            }.disposed(by: bag)
//            self.assetPlaybackService.playableItem.value = playables[assetIndex + 1]
//            self.selectedPlayable.value = self.assetPlaybackService.playableItem.value
        }
//        }
    }
    
    @objc func handleRemoteCommandPreviousTrackNotification(notification: Notification) {
        DDLogDebug("handleRemoteCommandPreviousTrackNotification notification: \(notification)")
        let playables: [Playable] = assetPlaybackService.playables.value
        
        guard let assetUuid = notification.userInfo?[Asset.uuidKey] as? String else { return }
        guard let assetIndex = playables.firstIndex(where: { $0.uuid == assetUuid }) else { return }
        
        if assetIndex > 0 {
            self.pausePlayback()
            self.previousPlayableTrack()
                .subscribe(onSuccess: { [weak self] previousPlayable in
                    if let _ = previousPlayable {
                        self?.assetPlaybackService.playableItem.value = previousPlayable
                        self?.selectedPlayable.value = self?.assetPlaybackService.playableItem.value
                    }
                }) { error in
                    DDLogDebug("error: \(error)")
            }.disposed(by: bag)
//            self.assetPlaybackService.playableItem.value = playables[assetIndex - 1]
//            self.selectedPlayable.value = self.assetPlaybackService.playableItem.value
        }
    }
    
//    @objc func handlePlayerRateDidChangeNotification(notification: Notification) {
//        DDLogDebug("handlePlayerRateDidChangeNotification notification: \(notification)")
//        playbackState.value = assetPlaybackService.assetPlaybackManager.state
//        //        updateTransportUIState()
//    }
//
//    @objc func handlePlayerDidPlayNotification(notification: Notification) {
//        os_log("handlePlayerDidPlayNotification", log: OSLog.data)
//        playbackState.value = assetPlaybackService.assetPlaybackManager.state
//        //        updateTransportUIState()
//    }
    
    @objc func handleAVPlayerItemDidPlayToEndTimeNotification(notification: Notification) {
        DDLogDebug("handleAVPlayerItemDidPlayToEndTimeNotification notification: \(notification)")
//        playbackState.value = assetPlaybackService.assetPlaybackManager.state
        
        //        if self.repeatMode == .repeatOff {
        //            NotificationCenter.default.post(name: AssetPlaybackManager.nextTrackNotification, object: nil, userInfo: [Asset.uuidKey: playbackAsset.uuid])
        //        } else if self.repeatMode == .repeatOne {
        //            assetPlaybackManager.seekTo(0)
        //            assetPlaybackManager.play()
        //        }
    }
    
    private func reactToReachability() {
        reachability.startNotifier().asObservable()
            .subscribe(onNext: { networkStatus in
                self.networkStatus.value = networkStatus
                
                switch networkStatus {
                case .unknown:
                    DDLogDebug("PlaybackControlsViewModel \(self.reachability.status.value)")
                case .notReachable:
                    DDLogDebug("PlaybackControlsViewModel \(self.reachability.status.value)")
                case .reachable(_):
                    DDLogDebug("PlaybackControlsViewModel \(self.reachability.status.value)")
                }
            }).disposed(by: bag)
    }
}

extension PlaybackControlsViewModel {
    func playableHasLocalFile() -> Bool {
        guard let playable: Playable = self.selectedPlayable.value,
            let path: String = playable.path,
            let percentEncoded: String = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let prodUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(percentEncoded))
            else { return false }
        
        var playableUuid: String?
        
        if playable is UserActionPlayable {
            if let userActionPlayable: UserActionPlayable = playable as? UserActionPlayable {
                playableUuid = userActionPlayable.playable_uuid
            }
        } else {
            playableUuid = playable.uuid
        }
                
        if let uuid: String = playableUuid {
            return FileManager.default.fileExists(atPath: URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(uuid.appending(String(describing: ".\(prodUrl.pathExtension)"))).path).path)
//            return FileManager.default.fileExists(atPath: url.path)
        } else {
            return false
        }
    }
}
