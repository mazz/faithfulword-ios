import Foundation
import AVFoundation
import RxSwift

public final class PlaybackControlsViewModel {
    // MARK: Fields
    public let assetPlaybackService: AssetPlaybackServicing
    private var bag = DisposeBag()
    // MARK: from client
    public private(set) var sliderScrubEvent = PublishSubject<Float>()
    public private(set) var repeatButtonTapEvent = PublishSubject<RepeatSetting>()
    // MARK: to client
    public private(set) var songTitle = Field<String>("")
    public private(set) var albumTitle = Field<String>("")
    public private(set) var albumArt = Field<UIImage?>(nil)
    public private(set) var estimatedPlaybackPosition = Field<Float>(Float(0))
    public private(set) var estimatedDuration = Field<Float>(Float(0))

    // MARK: --

    init(assetPlaybackService: AssetPlaybackServicing) {
        self.assetPlaybackService = assetPlaybackService
        
        // Add the notification observers needed to respond to events from the `AssetPlaybackManager`.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handleCurrentAssetDidChangeNotification(notification:)), name: AssetPlaybackManager.currentAssetDidChangeNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handleRemoteCommandNextTrackNotification(notification:)), name: AssetPlaybackManager.nextTrackNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handleRemoteCommandPreviousTrackNotification(notification:)), name: AssetPlaybackManager.previousTrackNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handlePlayerRateDidChangeNotification(notification:)), name: AssetPlaybackManager.playerRateDidChangeNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PlaybackControlsViewModel.handleAVPlayerItemDidPlayToEndTimeNotification(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)

        setupBindings()
    }
    
    func setupBindings() {
        sliderScrubEvent.asObservable()
            .subscribe(onNext: { [unowned self] scrubValue in
                DDLogDebug("scrubValue: \(scrubValue)")
                //                if let assetPlaybackService = self.assetPlaybackService {
                //                if let assetPlaybackManager = self.assetPlaybackService.assetPlaybackManager {
                self.assetPlaybackService.assetPlaybackManager.seekTo(Double(scrubValue))
                //                }
            })
            .disposed(by: bag)
        
        repeatButtonTapEvent.asObservable()
            .subscribe({ currentSetting in
                DDLogDebug("currentSetting: \(currentSetting)")
                //                if let assetPlaybackService = self.assetPlaybackService,
                if let repeatSetting = currentSetting.element {
                    //                        let assetPlaybackManager = self.assetPlaybackService.assetPlaybackManager
                    self.assetPlaybackService.assetPlaybackManager.repeatState = repeatSetting
                }
            })
            .disposed(by: bag)
    }
    
    // MARK: Notification Observer Methods
    
    @objc func handleCurrentAssetDidChangeNotification(notification: Notification) {
        DDLogDebug("handleCurrentAssetDidChangeNotification notification: \(notification)")

        if self.assetPlaybackService.assetPlaybackManager.asset != nil {
//            if let songAttribs: [NSAttributedString.Key : Any] = fullSongNameLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
//                fullSongNameLabel.attributedText = NSAttributedString(string: self.assetPlaybackService.assetPlaybackManager.asset.name, attributes: songAttribs)
//            }
//            if let albumAttribs: [NSAttributedString.Key : Any] = fullAlbumNameLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
//                fullAlbumNameLabel.attributedText = NSAttributedString(string: self.assetPlaybackService.assetPlaybackManager.asset.artist, attributes: albumAttribs)
//            }

        
            songTitle.value = self.assetPlaybackService.assetPlaybackManager.asset.name
            albumTitle.value = self.assetPlaybackService.assetPlaybackManager.asset.artist

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


            //            fullAlbumArtImageView.image = image
        }
        else {

            albumArt.value = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
            songTitle.value = "--"
            albumTitle.value = "--"


//            if let songAttribs: [NSAttributedString.Key : Any] = fullSongNameLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
//                fullSongNameLabel.attributedText = NSAttributedString(string: "--", attributes: songAttribs)
//            }
//            if let albumAttribs: [NSAttributedString.Key : Any] = fullAlbumNameLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
//                fullAlbumNameLabel.attributedText = NSAttributedString(string: "--", attributes: albumAttribs)
//            }

//            if let timeAttribs: [NSAttributedString.Key : Any] = fullCurrentPlaybackPositionLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
//                fullCurrentPlaybackPositionLabel.attributedText = NSAttributedString(string: "-:--", attributes: timeAttribs)
//                fullTotalPlaybackDurationLabel.attributedText = NSAttributedString(string: "-:--", attributes: timeAttribs)
//            }
//            fullPlaybackSlider.value = Float(0)
//
//            estimatedPlaybackPosition = Float(0)
//            estimatedDuration = Float(0)
//            resetUIDefaults()
        }
    }
    
    @objc func handleRemoteCommandNextTrackNotification(notification: Notification) {
        DDLogDebug("handleRemoteCommandNextTrackNotification notification: \(notification)")

//        let playables: [Playable] = playbackViewModel.assetPlaybackService.playables.value
//
//        guard let assetUuid = notification.userInfo?[Asset.uuidKey] as? String else { return }
//        guard let assetIndex = playables.index(where: { $0.uuid == assetUuid }) else { return }
//
//        if assetIndex < playables.count - 1 {
//            let playable: Playable = playables[assetIndex + 1]
//
//            guard let path: String = playable.path,
//                let localizedName: String = playable.localizedName,
//                let presenterName: String = playable.presenterName ?? self.albumTitle,
//                let prodUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path)) else { return }
//
//            let url: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(playable.uuid.appending(String(describing: ".\(prodUrl.pathExtension)"))).path)
//            playbackAsset = Asset(name: localizedName,
//                                  artist: presenterName,
//                                  uuid: playable.uuid,
//                                  fileExtension: prodUrl.pathExtension,
//                                  urlAsset: AVURLAsset(url: FileManager.default.fileExists(atPath: url.path) ? url : prodUrl))
//
//            assetPlaybackManager.asset = playbackAsset
//            downloadingViewModel.downloadAsset.value = playbackAsset
//            userActionsViewModel.playable = playable
//
//
//            //reset UI
//            resetUIDefaults()
//            assetPlaybackManager.seekTo(0)
//        }
    }
    
    @objc func handleRemoteCommandPreviousTrackNotification(notification: Notification) {
        DDLogDebug("handleRemoteCommandPreviousTrackNotification notification: \(notification)")

//        let playables: [Playable] = playbackViewModel.assetPlaybackService.playables.value
//
//        guard let assetUuid = notification.userInfo?[Asset.uuidKey] as? String else { return }
//        guard let assetIndex = playables.index(where: { $0.uuid == assetUuid }) else { return }
//
//        if assetIndex > 0 {
//            let playable: Playable = playables[assetIndex - 1]
//
//            guard let path: String = playable.path,
//                let localizedName: String = playable.localizedName,
//                let presenterName: String = playable.presenterName ?? self.albumTitle,
//                let prodUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path)) else { return }
//
//            // play local file if available
//            let url: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(playable.uuid.appending(String(describing: ".\(prodUrl.pathExtension)"))).path)
//            playbackAsset = Asset(name: localizedName,
//                                  artist: presenterName,
//                                  uuid: playable.uuid,
//                                  fileExtension: prodUrl.pathExtension,
//                                  urlAsset: AVURLAsset(url: FileManager.default.fileExists(atPath: url.path) ? url : prodUrl))
//
//            assetPlaybackManager.asset = playbackAsset
//            downloadingViewModel.downloadAsset.value = playbackAsset
//            userActionsViewModel.playable = playable
//
//            //reset UI
//            resetUIDefaults()
//            assetPlaybackManager.seekTo(0)
//        }
    }
    
    @objc func handlePlayerRateDidChangeNotification(notification: Notification) {
        DDLogDebug("handlePlayerRateDidChangeNotification notification: \(notification)")
//        updateTransportUIState()
    }
    
    @objc func handleAVPlayerItemDidPlayToEndTimeNotification(notification: Notification) {
        DDLogDebug("handleAVPlayerItemDidPlayToEndTimeNotification notification: \(notification)")

//        if self.repeatMode == .repeatOff {
//            NotificationCenter.default.post(name: AssetPlaybackManager.nextTrackNotification, object: nil, userInfo: [Asset.uuidKey: playbackAsset.uuid])
//        } else if self.repeatMode == .repeatOne {
//            assetPlaybackManager.seekTo(0)
//            assetPlaybackManager.play()
//        }
    }
}

