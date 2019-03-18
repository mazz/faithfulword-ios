import Foundation
import AVFoundation
import RxSwift

public final class PlaybackControlsViewModel {
    // MARK: Fields
    public let assetPlaybackService: AssetPlaybackServicing
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

    
//    public private(set) var estimatedPlaybackPosition = Field<Float>(Float(0))
//    public private(set) var estimatedDuration = Field<Float>(Float(0))
    
    // MARK: --
    
    init(assetPlaybackService: AssetPlaybackServicing,
         reachability: RxClassicReachable) {
        self.assetPlaybackService = assetPlaybackService
        self.reachability = reachability
        
        // Add the notification observers needed to respond to events from the `AssetPlaybackManager`.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handleCurrentAssetDidChangeNotification(notification:)), name: AssetPlaybackManager.currentAssetDidChangeNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handleRemoteCommandNextTrackNotification(notification:)), name: AssetPlaybackManager.nextTrackNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handleRemoteCommandPreviousTrackNotification(notification:)), name: AssetPlaybackManager.previousTrackNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handlePlayerRateDidChangeNotification(notification:)), name: AssetPlaybackManager.playerRateDidChangeNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handleAVPlayerItemDidPlayToEndTimeNotification(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
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
                self.assetPlaybackService.assetPlaybackManager.seekTo(Double(scrubValue))
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
                    self.assetPlaybackService.assetPlaybackManager.pause()
                    self.playDisabled.value = !fileExists
                case .notReachable:
                    if !fileExists {
                        self.assetPlaybackService.assetPlaybackManager.pause()
                    }
                    self.playDisabled.value = !fileExists
                case .reachable(_):
                    self.assetPlaybackService.assetPlaybackManager.play()
                    self.playDisabled.value = false
                }
                
            }
            .disposed(by: bag)
    }
    
    // MARK: Notification Observer Methods
    
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
            self.assetPlaybackService.assetPlaybackManager.pause()
            self.playDisabled.value = !fileExists
        case .notReachable:
            if !fileExists {
                self.assetPlaybackService.assetPlaybackManager.pause()
            }
            self.playDisabled.value = !fileExists
        case .reachable(_):
            self.assetPlaybackService.assetPlaybackManager.play()
            self.playDisabled.value = false
        }
    }
    
    @objc func handleRemoteCommandNextTrackNotification(notification: Notification) {
        DDLogDebug("handleRemoteCommandNextTrackNotification notification: \(notification)")
        
        let playables: [Playable] = assetPlaybackService.playables.value
        
        guard let assetUuid = notification.userInfo?[Asset.uuidKey] as? String else { return }
        guard let assetIndex = playables.index(where: { $0.uuid == assetUuid }) else { return }
        
        if assetIndex < playables.count - 1 { self.playbackPlayable.value = playables[assetIndex + 1] }
//        playbackState.value = assetPlaybackService.assetPlaybackManager.state
    }
    
    @objc func handleRemoteCommandPreviousTrackNotification(notification: Notification) {
        DDLogDebug("handleRemoteCommandPreviousTrackNotification notification: \(notification)")
        let playables: [Playable] = assetPlaybackService.playables.value
        
        guard let assetUuid = notification.userInfo?[Asset.uuidKey] as? String else { return }
        guard let assetIndex = playables.index(where: { $0.uuid == assetUuid }) else { return }
        
        if assetIndex > 0 { self.playbackPlayable.value = playables[assetIndex - 1] }
//        playbackState.value = assetPlaybackService.assetPlaybackManager.state
    }
    
    @objc func handlePlayerRateDidChangeNotification(notification: Notification) {
        DDLogDebug("handlePlayerRateDidChangeNotification notification: \(notification)")
        playbackState.value = assetPlaybackService.assetPlaybackManager.state
        //        updateTransportUIState()
    }
    
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
        guard let playable: Playable = self.playbackPlayable.value,
            let path: String = playable.path,
            let prodUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path))
            else { return false }
        
        let url: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(playable.uuid.appending(String(describing: ".\(prodUrl.pathExtension)"))).path)
        return FileManager.default.fileExists(atPath: url.path)

    }
}
