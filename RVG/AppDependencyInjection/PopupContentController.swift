//
//  PopupContentController.swift
//

import UIKit
import LNPopupController
import AVFoundation
import RxSwift
import RxCocoa
import MarqueeLabel
import Moya

public enum PlaybackSpeed {
    case oneX
    case onePointTwoFiveX
    case onePointFiveX
}

public enum RepeatSetting {
    case repeatOff
    case repeatOne
    case repeatAll
}

public enum DownloadSetting {
    case initial
    case downloadingInitiated
    case downloadingInProgress
    case downloadingComplete
    case downloadingFailed
}

class PopupContentController: UIViewController {

    @IBOutlet weak var fullSongNameLabel: MarqueeLabel!
    @IBOutlet weak var fullAlbumNameLabel: MarqueeLabel!
    @IBOutlet weak var fullPlayPauseButton: UIButton!
    @IBOutlet weak var fullPlaybackSlider: UISlider!

    @IBOutlet weak var fullAlbumArtImageView: UIImageView!

    @IBOutlet weak var fullCurrentPlaybackPositionLabel: UILabel!
    @IBOutlet weak var fullTotalPlaybackDurationLabel: UILabel!
    @IBOutlet weak var fullRepeatButton: UIButton!
    @IBOutlet weak var fullDownloadShareButton: UIButton!
    @IBOutlet weak var fullToggleSpeedButton: UIButton!

    var estimatedPlaybackPosition: Float = Float(0)
    var estimatedDuration: Float = Float(0)

    let dateComponentFormatter = DateComponentsFormatter()
    let accessibilityDateComponentsFormatter = DateComponentsFormatter()

    // bar
    var playPauseButton: UIBarButtonItem!
    var nextButton: UIBarButtonItem!

    internal var playbackAsset: Asset!
    //    internal var playables: [Playable]!

    //    public var playlistAssets = [Asset]()

    // MARK: Fields
    var scrubbing: Bool = false
    var playingWhileScrubbing: Bool = false

    public var playbackViewModel: PlaybackControlsViewModel!
    public var downloadingViewModel: DownloadingViewModel!

    private let sliderInUse = Variable<Bool>(false)

    //    private let sliderInUse = BehaviorSubject<Bool>(value: false) //ReplaySubject<Bool>.create(bufferSize: 1) //Field<Bool>(false)
    internal let actualPlaybackProgress = Field<Float>(0)
//    internal let repeatState = Field<RepeatSetting>(.none)

    private var repeatMode: RepeatSetting = .repeatOff {
        didSet {
            self.fullRepeatButton.setImage((repeatMode == .repeatOne) ? #imageLiteral(resourceName: "repeat-2") : #imageLiteral(resourceName: "repeat"), for: .normal)
        }
    }
    private var downloadMode: DownloadSetting = .initial {
        didSet {
            print("dowload mode set to: \(downloadMode)")

//            self.fullRepeatButton.setImage((repeatMode == .repeatOne) ? #imageLiteral(resourceName: "repeat-2") : #imageLiteral(resourceName: "repeat"), for: .normal)
        }
    }

    private var bag = DisposeBag()

    var playbackRepeat : Bool?
    //    var muteVolume : Bool?
    var playbackSpeed: PlaybackSpeed = .oneX

    var assetPlaybackManager: AssetPlaybackManager! {
        didSet {
            // Add the Key-Value Observers needed to keep the UI up to date.
            //            assetPlaybackManager.addObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.percentProgress), options: NSKeyValueObservingOptions.new, context: nil)
            assetPlaybackManager.addObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.duration), options: NSKeyValueObservingOptions.new, context: nil)
            assetPlaybackManager.addObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.playbackPosition), options: NSKeyValueObservingOptions.new, context: nil)

            // Add the notification observers needed to respond to events from the `AssetPlaybackManager`.
            let notificationCenter = NotificationCenter.default

            notificationCenter.addObserver(self, selector: #selector(PopupContentController.handleCurrentAssetDidChangeNotification(notification:)), name: AssetPlaybackManager.currentAssetDidChangeNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(PopupContentController.handleRemoteCommandNextTrackNotification(notification:)), name: AssetPlaybackManager.nextTrackNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(PopupContentController.handleRemoteCommandPreviousTrackNotification(notification:)), name: AssetPlaybackManager.previousTrackNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(PopupContentController.handlePlayerRateDidChangeNotification(notification:)), name: AssetPlaybackManager.playerRateDidChangeNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(PopupContentController.handleAVPlayerItemDidPlayToEndTimeNotification(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: playbackAsset)

        }
    }

    var songTitle: String = "" {
        didSet {
            if isViewLoaded {
                fullSongNameLabel.text = songTitle
            }

            popupItem.title = songTitle
        }
    }
    var albumTitle: String = "" {
        didSet {
            if isViewLoaded {
                fullAlbumNameLabel.text = albumTitle
            }
            //            if ProcessInfo.processInfo.operatingSystemVersion.majorVersion <= 9 {
            popupItem.subtitle = albumTitle
            //            }
        }
    }
    var albumArt: UIImage = UIColor.red.image(size: CGSize(width: 128, height: 128)) {
        didSet {
            if isViewLoaded {
                fullAlbumArtImageView.image = albumArt
            }
            popupItem.image = albumArt
            popupItem.accessibilityImageLabel = NSLocalizedString("Album Art", comment: "")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        playPauseButton = UIBarButtonItem(image: UIImage(named: "play"), style: .plain, target: self, action: #selector(PopupContentController.doPlayPause))
        //        playPauseButton.action = #selector(PopupContentController.doPlayPause)

        //for: .normal, style: .plain, barMetrics: .compact)

        //        playPauseButton = UIBarButtonItem(image: UIImage(named: "pause"), style: .plain, target: self, action: #selector(PopupContentController.doPlayPause))
        playPauseButton.accessibilityLabel = NSLocalizedString("Play", comment: "")
        nextButton = UIBarButtonItem(image: UIImage(named: "nextFwd"), style: .plain, target: self, action: #selector(PopupContentController.handleUserDidPressForwardButton))
        nextButton.accessibilityLabel = NSLocalizedString("Next Track", comment: "")

        popupItem.rightBarButtonItems = [ playPauseButton, nextButton ]

    }

    func bindUI() {
        reset()

        fullDownloadShareButton.rx.tap
            .map { [unowned self] _ in //self.repeatMode
                var downloadSetting: DownloadSetting!
                if self.downloadMode == .initial {
                    downloadSetting = .downloadingInitiated
                }
                else if self.downloadMode == .downloadingInitiated {
                    downloadSetting = .downloadingInitiated
                }
                self.downloadMode = downloadSetting

                // FIXME: HACK: probably a better way to sync the download view model
                self.downloadingViewModel.downloadAsset = self.playbackAsset
                return self.downloadMode
            }
            .bind(to: downloadingViewModel.downloadButtonTapEvent)
            .disposed(by: bag)

        fullRepeatButton.rx.tap
            .map { [unowned self] _ in //self.repeatMode
                var repeatSetting: RepeatSetting!
                if self.repeatMode == .repeatOff {
                    repeatSetting = .repeatOne
                } else if self.repeatMode == .repeatOne {
                    repeatSetting = .repeatOff
                }
                self.repeatMode = repeatSetting
                return self.repeatMode
            }
            .bind(to: playbackViewModel.repeatButtonTapEvent)
            .disposed(by: bag)

        fullPlaybackSlider.rx.value.asObservable()
            .map { Float($0) }
            .do(onNext: { time in
                print("time: \(time)")
            })
            .distinctUntilChanged()
            .throttle(0.3, scheduler: MainScheduler.instance)
            .bind(to: playbackViewModel.sliderScrubEvent)
            .disposed(by: bag)
        fullPlaybackSlider.isContinuous = true
        fullPlaybackSlider.isMultipleTouchEnabled = false

        actualPlaybackProgress.asObservable()
            .observeOn(MainScheduler.instance)
            .filter { [unowned self] _ in !self.sliderInUse.value }
            //            .map { Float($0) }
            .debounce(0.4, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] progress in
                self.fullPlaybackSlider.value = progress
                print("field progress: \(progress)")
            })
            .disposed(by: bag)

        listenForSliderUserEvents()
    }

    func listenForSliderUserEvents() {
        let inUseObservable = fullPlaybackSlider.rx
            .controlEvent([.touchDown, .touchDragInside])
            .map { true }

        let notInUseObservable = fullPlaybackSlider.rx
            .controlEvent([.touchUpInside,
                           .touchUpOutside,
                           .touchDownRepeat,
                           .touchDragOutside,
                           .touchDragEnter,
                           .touchDragExit,
                           .touchCancel])
            .map { false }
        Observable.merge([inUseObservable, notInUseObservable])
            .bind(to: sliderInUse)
            .disposed(by: bag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // assetPlaybackService.playableItem should be valid pointer
        // because it should be set when the user taps a row in MediaListingViewModel

        guard let assetPlaybackService = playbackViewModel.assetPlaybackService,
            let item: Playable = assetPlaybackService.playableItem.value,
            let path: String = item.path,
            let localizedName: String = item.localizedName,
            let presenterName: String = item.presenterName,
            let url: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path))
            else { return }
        self.assetPlaybackManager = assetPlaybackService.assetPlaybackManager

        // stop because there could an asset currently playing
        assetPlaybackManager.stop()

        playbackAsset = Asset(name: localizedName,
                              artist: presenterName,
                              uuid: item.uuid,
                              urlAsset: AVURLAsset(url: url))
        assetPlaybackManager.asset = playbackAsset

        //        playables = assetPlaybackService.playables.value

        bindUI()

        dateComponentFormatter.unitsStyle = .positional
        dateComponentFormatter.allowedUnits = [.minute, .second]
        dateComponentFormatter.zeroFormattingBehavior = [.pad]

        fullPlaybackSlider.thumbTintColor = UIColor.darkGray

        fullPlayPauseButton.addTarget(self, action: #selector(PopupContentController.doPlayPause), for: .touchUpInside)

        fullSongNameLabel.text = songTitle
        fullSongNameLabel.fadeLength = 10.0
        fullSongNameLabel.speed = .duration(8.0)

        fullAlbumNameLabel.text = albumTitle
        fullAlbumNameLabel.fadeLength = 10.0
        fullAlbumNameLabel.speed = .duration(8.0)

        fullAlbumArtImageView.layer.shadowColor = UIColor.darkGray.cgColor
        fullAlbumArtImageView.layer.shadowOffset = CGSize(width: 2, height: 4)
        fullAlbumArtImageView.layer.shadowOpacity = 0.8
        fullAlbumArtImageView.layer.shadowRadius = 4.0
        fullAlbumArtImageView.clipsToBounds = false
//        fullAlbumArtImageView.image = albumArt

        popupItem.title = songTitle
        popupItem.subtitle = albumTitle

        // Add the notification observers needed to respond to events from the `AssetPlaybackManager`.
        //        let notificationCenter = NotificationCenter.default
        //
        //        notificationCenter.addObserver(self, selector: #selector(DemoMusicPlayerController.handleRemoteCommandNextTrackNotification(notification:)), name: AssetPlaybackManager.nextTrackNotification, object: nil)
        //        notificationCenter.addObserver(self, selector: #selector(DemoMusicPlayerController.handleRemoteCommandPreviousTrackNotification(notification:)), name: AssetPlaybackManager.previousTrackNotification, object: nil)

    }

    deinit {
        // Remove all KVO and notification observers.
        let notificationCenter = NotificationCenter.default

        notificationCenter.removeObserver(self, name: AssetPlaybackManager.currentAssetDidChangeNotification, object: nil)
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.previousTrackNotification, object: nil)
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.nextTrackNotification, object: nil)
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.playerRateDidChangeNotification, object: nil)

        //        assetPlaybackManager.removeObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.percentProgress))
        assetPlaybackManager.removeObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.duration))
        assetPlaybackManager.removeObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.playbackPosition))
    }

    // MARK: Private

    private func reset() {
        bag = DisposeBag()
    }

    @objc func doPlayPause() {
        assetPlaybackManager.togglePlayPause()

//        updateToolbarItemState()
    }

    // MARK: Target-Action Methods

    @IBAction func download(_ sender: Any) {
        print("download action")
//        let provider = MoyaProvider<FileWebService>(plugins: [NetworkLoggerPlugin(verbose: WebService.verbose)])
//
//        if let urlString: String = playbackAsset?.urlAsset.url.absoluteString {
//            provider.request(FileWebService.download(url: urlString, filename: playbackAsset.uuid, fileExtension: nil), callbackQueue: nil, progress: { progressResponse in
//                print("progressResponse: \(progressResponse)")
//            }) { result in
//                print("result: \(result)")
//                switch result {
//                case let .success(response):
//                    let statusCode = response.statusCode
//                    if let dataString: String = String(data: response.data, encoding: .utf8) {
//                        print(".success: \(dataString)")
//                        print(".success statusCode: \(statusCode)")
//                    }
//
//                case .failure(_):
//                    if let error = result.error {
//                        print(".failure: \(String(describing: error.errorDescription)))")
//                    }
//                }
//            }
//        }

    }

    @IBAction func togglePlaybackSpeed(_ sender: Any) {
        var speedTitle: String

        //        switch speed {
        if playbackSpeed == .oneX {
            playbackSpeed = .onePointTwoFiveX
            speedTitle = "1.25"
            fullToggleSpeedButton.setTitle(speedTitle.appending("x"), for: .normal)
        }
        else if playbackSpeed == .onePointTwoFiveX {
            playbackSpeed = .onePointFiveX
            speedTitle = "1.5"
            fullToggleSpeedButton.setTitle(speedTitle.appending("x"), for: .normal)
        }
        else if playbackSpeed == .onePointFiveX {
            playbackSpeed = .oneX
            speedTitle = "1.0"
            fullToggleSpeedButton.setTitle(speedTitle.appending("x"), for: .normal)
        }

        //        PlaybackService.sharedInstance().playbackSpeed = playbackSpeed
    }

    @IBAction func handleUserDidPressBackwardButton(_ sender: Any) {
        if assetPlaybackManager.playbackPosition < 5.0 {
            // If the currently playing asset is less than 5 seconds into playback then skip to the previous `Asset`.
            assetPlaybackManager.previousTrack()
        }
        else {
            // Otherwise seek back to the beginning of the currently playing `Asset`.
            assetPlaybackManager.seekTo(0)
        }
    }

    @IBAction func handleUserDidPressForwardButton(_ sender: Any) {
        assetPlaybackManager.nextTrack()
    }


    //    @objc func doNextTrack() {
    //
    //    }



    @objc func updateTransportUIState() {
        guard let pauseImage: UIImage = UIImage(named: "pause"),
            let playImage: UIImage = UIImage(named: "play"),
            let fullPlayImage: UIImage = UIImage(named: "nowPlaying_play"),
            let fullPauseImage: UIImage = UIImage(named: "nowPlaying_pause")
            else { return }
        print("updateTransportUIState")
        if assetPlaybackManager.asset == nil {
            //            backwardButton.isEnabled = false
            playPauseButton.isEnabled = false
            nextButton.isEnabled = false

            playPauseButton.image = UIImage(named: "play")
        }
        else {
            //            backwardButton.isEnabled = true
            playPauseButton.isEnabled = true
            nextButton.isEnabled = true

            if assetPlaybackManager.state != .playing {
                playPauseButton.image = UIImage(named: "play")
            }
            else {
                playPauseButton.image = UIImage(named: "pause")
            }
        }

        let accessibilityPlay: String = NSLocalizedString("Play", comment: "")
        let accessibilityPause: String = NSLocalizedString("Pause", comment: "")

        if assetPlaybackManager.state == .playing {
            playPauseButton.image = pauseImage
            playPauseButton.accessibilityLabel = accessibilityPause

            fullPlayPauseButton.setImage(fullPauseImage, for: .normal)
            fullPlayPauseButton.accessibilityLabel = accessibilityPause
        } else if assetPlaybackManager.state == .paused {
            playPauseButton.image = playImage
            playPauseButton.accessibilityLabel = accessibilityPlay

            fullPlayPauseButton.setImage(fullPlayImage, for: .normal)
            fullPlayPauseButton.accessibilityLabel = accessibilityPlay
        }

    }

    @objc func emptyUIState() {
        if let playbackSpeed: Float = UserDefaults.standard.object(forKey: UserPrefs.playbackSpeed.rawValue) as? Float {

            print("print rate: \(String(describing:playbackSpeed))")
            switch playbackSpeed {
            case 1.0:
                self.playbackSpeed = .oneX
            case 1.25:
                self.playbackSpeed = .onePointTwoFiveX
            case 1.5:
                self.playbackSpeed = .onePointFiveX
            default:
                self.playbackSpeed = .oneX
            }

            fullToggleSpeedButton.setTitle(String(describing:playbackSpeed).appending("x"), for: .normal)
        }
        fullCurrentPlaybackPositionLabel.text = "-:--"
        fullTotalPlaybackDurationLabel.text = "-:--"
        fullPlayPauseButton.setImage(UIImage(named: "nowPlaying_play"), for: .normal)

        updateTransportUIState()

        //        self.repeatButton.setImage(#imageLiteral(resourceName: "repeat"), for: .normal)
    }
    // MARK: Key-Value Observing Method

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AssetPlaybackManager.duration) {
            let duration: Float = Float(assetPlaybackManager.duration)
            //            print("duration: \(duration)")
            if !duration.isNaN {
                estimatedDuration = duration
                //                print("assetPlaybackManager.duration: \(assetPlaybackManager.duration)")
                fullPlaybackSlider.minimumValue = Float(0)
                fullPlaybackSlider.maximumValue = assetPlaybackManager.duration
                //                guard let stringValue = dateComponentFormatter.string(from: TimeInterval(assetPlaybackManager.duration)) else { return }
                //                totalPlaybackDurationLabel.text = stringValue
            }

        }
        else if keyPath == #keyPath(AssetPlaybackManager.playbackPosition) {
            let playbackPosition: Float = Float(assetPlaybackManager.playbackPosition)
            //            print("playbackPosition: \(playbackPosition)")
            if !playbackPosition.isNaN {
                estimatedPlaybackPosition = playbackPosition
                //                print("assetPlaybackManager.playbackPosition: \(assetPlaybackManager.playbackPosition)")
                guard let stringValue = dateComponentFormatter.string(from: TimeInterval(assetPlaybackManager.playbackPosition)) else { return }
                fullCurrentPlaybackPositionLabel.text = stringValue

                actualPlaybackProgress.value = assetPlaybackManager.playbackPosition
                //                fullPlaybackSlider.value = assetPlaybackManager.playbackPosition

                if estimatedDuration != 0 {
                    let remainingTime: Float = Float(estimatedDuration - assetPlaybackManager.playbackPosition)
                    guard let stringValue = dateComponentFormatter.string(from: TimeInterval(remainingTime)) else { return }
                    fullTotalPlaybackDurationLabel.text = String("-").appending(stringValue)

                } else {
                    fullCurrentPlaybackPositionLabel.text = "-:--"
                    fullTotalPlaybackDurationLabel.text = "-:--"
                }
            }
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // MARK: Notification Observer Methods

    @objc func handleCurrentAssetDidChangeNotification(notification: Notification) {
        if assetPlaybackManager.asset != nil {
            fullSongNameLabel.text = assetPlaybackManager.asset.name
            fullAlbumNameLabel.text = assetPlaybackManager.asset.artist

            songTitle = assetPlaybackManager.asset.name
            albumTitle = assetPlaybackManager.asset.artist

            guard let asset = assetPlaybackManager.asset else {
                return
            }

            let urlAsset = asset.urlAsset

            let artworkData = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common).first?.value as? Data ?? Data()

            let image = UIImage(data: artworkData) ?? UIColor.lightGray.image(size: CGSize(width: 128, height: 128))

            //            fullAlbumArtImageView.image = image
            albumArt = image

            //            for i in assets.startIndex..<assets.endIndex {
            //                if asset.assetName == assets[i].assetName {
            //                    assetListTableView.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
            //                    break
            //                }
            //            }
        }
        else {

            albumArt = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
            fullSongNameLabel.text = "--"
            fullAlbumNameLabel.text = "--"
            fullTotalPlaybackDurationLabel.text = "-:--"
            fullCurrentPlaybackPositionLabel.text = "-:--"
            fullPlaybackSlider.value = Float(0)

            estimatedPlaybackPosition = Float(0)
            estimatedDuration = Float(0)

            emptyUIState()
            //            assetListTableView.deselectAll(nil)
        }

//        updateToolbarItemState()
    }

    @objc func handleRemoteCommandNextTrackNotification(notification: Notification) {
        guard let assetPlaybackService = playbackViewModel.assetPlaybackService else { return }
        let playables: [Playable] = assetPlaybackService.playables.value

        guard let assetUuid = notification.userInfo?[Asset.uuidKey] as? String else { return }
        guard let assetIndex = playables.index(where: { $0.uuid == assetUuid }) else { return }

        if assetIndex < playables.count - 1 {
            let playable: Playable = playables[assetIndex + 1]

            guard let path: String = playable.path,
                let localizedName: String = playable.localizedName,
                let presenterName: String = playable.presenterName,
                let url: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path)) else { return }


            playbackAsset = Asset(name: localizedName,
                                  artist: presenterName,
                                  uuid: playable.uuid,
                                  urlAsset: AVURLAsset(url: url))
            assetPlaybackManager.asset = playbackAsset
        }
    }

    @objc func handleRemoteCommandPreviousTrackNotification(notification: Notification) {
        guard let assetPlaybackService = playbackViewModel.assetPlaybackService else { return }
        let playables: [Playable] = assetPlaybackService.playables.value

        guard let assetUuid = notification.userInfo?[Asset.uuidKey] as? String else { return }
        guard let assetIndex = playables.index(where: { $0.uuid == assetUuid }) else { return }

        if assetIndex > 0 {
            let playable: Playable = playables[assetIndex - 1]

            guard let path: String = playable.path,
                let localizedName: String = playable.localizedName,
                let presenterName: String = playable.presenterName,
                let url: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path)) else { return }

            playbackAsset = Asset(name: localizedName,
                                  artist: presenterName,
                                  uuid: playable.uuid,
                                  urlAsset: AVURLAsset(url: url))
            assetPlaybackManager.asset = playbackAsset
        }
    }

    @objc func handlePlayerRateDidChangeNotification(notification: Notification) {
        updateTransportUIState()
    }

    @objc func handleAVPlayerItemDidPlayToEndTimeNotification(notification: Notification) {
        if self.repeatMode == .repeatOff {
//            self.handleRemoteCommandNextTrackNotification(notification: notification)
            NotificationCenter.default.post(name: AssetPlaybackManager.nextTrackNotification, object: nil, userInfo: [Asset.uuidKey: playbackAsset.uuid])
        } else if self.repeatMode == .repeatOne {
            assetPlaybackManager.seekTo(0)
            assetPlaybackManager.play()
        }
    }
}
