import UIKit
import LNPopupController
import AVFoundation
import RxSwift
import RxCocoa
import MarqueeLabel
import Moya
import UICircularProgressRing

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

class PopupContentController: UIViewController {
    
    @IBOutlet weak var fullSongNameLabel: MarqueeLabel!
    @IBOutlet weak var fullAlbumNameLabel: MarqueeLabel!
    @IBOutlet weak var fullPlayPauseButton: UIButton!
    @IBOutlet weak var fullPlaybackSlider: UISlider!
    
    @IBOutlet weak var fullAlbumArtImageView: UIImageView!
    
    @IBOutlet weak var fullCurrentPlaybackPositionLabel: UILabel!
    @IBOutlet weak var fullTotalPlaybackDurationLabel: UILabel!
    @IBOutlet weak var fullRepeatButton: UIButton!
    @IBOutlet weak var fullDownloadButton: UIButton!
    @IBOutlet weak var fullToggleSpeedButton: UIButton!
    @IBOutlet weak var fullDownloadProgress: UICircularProgressRing!
    @IBOutlet weak var fullProgressDownloadButton: UIButton!
    @IBOutlet weak var fullProgressShareButton: UIButton!
    
    var estimatedPlaybackPosition: Float = Float(0)
    var estimatedDuration: Float = Float(0)
    
    let dateComponentFormatter = DateComponentsFormatter()
    let accessibilityDateComponentsFormatter = DateComponentsFormatter()
    
    // bar
    var playPauseButton: UIBarButtonItem!
    var nextButton: UIBarButtonItem!
    
    // MARK: Fields
    internal var playbackAsset: Asset!
    public var downloadState = Field<FileDownloadState>(.initial)
    // the state of the download button image name
    //    public let downloadImageNameEvent = Field<String>("download_icon_black")
    
    var scrubbing: Bool = false
    var playingWhileScrubbing: Bool = false
    
    public var playbackViewModel: PlaybackControlsViewModel!
    public var downloadingViewModel: DownloadingViewModel!
    public var userActionsViewModel: UserActionsViewModel!
    
    private let sliderInUse = Variable<Bool>(false)
    
    //    private let sliderInUse = BehaviorSubject<Bool>(value: false) //ReplaySubject<Bool>.create(bufferSize: 1) //Field<Bool>(false)
    internal let actualPlaybackProgress = Field<Float>(0)
    //    internal let repeatState = Field<RepeatSetting>(.none)
    
    private var repeatMode: RepeatSetting = .repeatOff {
        didSet {
            self.fullRepeatButton.setImage((repeatMode == .repeatOne) ? #imageLiteral(resourceName: "repeat-2") : #imageLiteral(resourceName: "repeat"), for: .normal)
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
                if let songAttribs: [NSAttributedString.Key : Any] = fullSongNameLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
                    fullSongNameLabel.attributedText = NSAttributedString(string: songTitle, attributes: songAttribs)
                }
//                fullSongNameLabel.text = songTitle
            }
            
            popupItem.title = songTitle
        }
    }
    var albumTitle: String = "" {
        didSet {
            if isViewLoaded {
                if let albumAttribs: [NSAttributedString.Key : Any] = fullAlbumNameLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
                    fullAlbumNameLabel.attributedText = NSAttributedString(string: albumTitle, attributes: albumAttribs)
                }

//                fullAlbumNameLabel.text = albumTitle
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
        resetUIBindings()
        
        // hide progress button on completion or initial
        downloadState.asObservable()
            .observeOn(MainScheduler.instance)
//            .map { fileDownloadState in fileDownloadState == .initial || fileDownloadState == .complete }
            .map { fileDownloadState in fileDownloadState != .inProgress }
            .bind(to: fullDownloadProgress.rx.isHidden)
            .disposed(by: bag)
        
        // hide progress stop button on completion or initial
        downloadState.asObservable()
            .observeOn(MainScheduler.instance)
//            .map { fileDownloadState in fileDownloadState == .initial || fileDownloadState == .complete }
            .map { fileDownloadState in fileDownloadState != .inProgress }
            .bind(to: fullProgressDownloadButton.rx.isHidden)
            .disposed(by: bag)
        
        // hide download button during download
        //        downloadState.asObservable()
        //            .observeOn(MainScheduler.instance)
        //            .map { fileDownloadState in fileDownloadState == .inProgress }
        //            .bind(to: fullDownloadButton.rx.isHidden)
        //            .disposed(by: bag)
        
        // hide download button if download complete
        downloadState.asObservable()
            .observeOn(MainScheduler.instance)
            .map { fileDownloadState in fileDownloadState != .initial }
            .bind(to: fullDownloadButton.rx.isHidden)
            .disposed(by: bag)
        
        // hide share button if not downloaded yet
        downloadState.asObservable()
            .observeOn(MainScheduler.instance)
            .map { fileDownloadState in fileDownloadState != .complete }
            .bind(to: fullProgressShareButton.rx.isHidden)
            .disposed(by: bag)
        
        
        // set image name based on state
        //        downloadImageNameEvent.asObservable()
        //            .observeOn(MainScheduler.instance)
        //            .map { UIImage(named: $0) }
        //            .bind(to: fullDownloadButton.rx.image(for: .normal))
        //            .disposed(by: bag)
        
        // set progress UI during download
        // FIXME: the old playback service will not deallocate because of this chunk
        //        downloadingViewModel.fileDownload.asObservable()
        //            .observeOn(MainScheduler.instance)
        //            .filterNils()
        //            .subscribe(onNext: { fileDownload in
        //
        //                self.fullDownloadProgress.maxValue =  CGFloat(fileDownload.totalCount)
        //                self.fullDownloadProgress.value = CGFloat(fileDownload.completedCount)
        //                DDLogDebug("downloadingViewModel.fileDownload: \(fileDownload.localUrl) | \(fileDownload.completedCount) / \(fileDownload.totalCount)(\(fileDownload.progress) | \(fileDownload.state))")
        //            })
        //            .disposed(by: bag)
        

        // initiate download
        fullDownloadButton.rx.tap
            .map { //[unowned self] _ in
                DDLogDebug("fullDownloadButton.rx.tap")
                // FIXME: HACK: probably a better way to sync the download view model
                //                self.downloadingViewModel.downloadAsset = self.playbackAsset
                return .initial
            }
            .bind(to: downloadingViewModel.downloadButtonTapEvent)
            .disposed(by: bag)
        
        // cancel download
        fullProgressDownloadButton.rx.tap
            .map { return .cancelling }
            .bind(to: downloadingViewModel.cancelDownloadButtonTapEvent)
            .disposed(by: bag)
        
        // bind repeat track state
        fullRepeatButton.rx.tap
            .map { [unowned self] _ in
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
        
        // when the user scrubs, limit the frequency of the
        // sending of the scrub event to every 0.3 seconds
        // in order to send a little more frequently than
        // how frequently the slider playback position is updated
        fullPlaybackSlider.rx.value.asObservable()
            .observeOn(MainScheduler.instance)
            .map { Float($0) }
            .do(onNext: { time in
//                DDLogDebug("time: \(time)")
            })
            .distinctUntilChanged()
            .throttle(0.3, scheduler: MainScheduler.instance)
            .bind(to: playbackViewModel.sliderScrubEvent)
            .disposed(by: bag)
        fullPlaybackSlider.isContinuous = true
        fullPlaybackSlider.isMultipleTouchEnabled = false
        
        // check to update the slider position around every 0.4 seconds
        // as long as the user is not scrubbing
        actualPlaybackProgress.asObservable()
            .observeOn(MainScheduler.instance)
            .filter { [unowned self] _ in !self.sliderInUse.value }
            .debounce(0.2, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] progress in
                self.fullPlaybackSlider.value = progress
                DDLogDebug("field progress: \(progress)")
            })
            .disposed(by: bag)
        
        listenForSliderUserEvents()
        
        actualPlaybackProgress.asObservable()
            .observeOn(MainScheduler.instance)
            .bind(to: userActionsViewModel.progressEvent)
            .disposed(by: bag)
        
        userActionsViewModel.playbackHistory
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { playable in
                DDLogDebug("top playable: \(playable.first)")
            })
            .disposed(by: bag)
//            .map { $0 }
//            .do(onNext: { playables in
//                DDLogDebug("top playable: \(playables.first)")
//            })
//            .disposed(by: bag)
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
            let presenterName: String = item.presenterName ?? self.albumTitle,
            let prodUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path))
            else { return }
        self.assetPlaybackManager = assetPlaybackService.assetPlaybackManager
        
        // stop because there could an asset currently playing
        assetPlaybackManager.stop()
        
        // play local file if available
        let url: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(item.uuid.appending(String(describing: ".\(prodUrl.pathExtension)"))).path)
        playbackAsset = Asset(name: localizedName,
                              artist: presenterName,
                              uuid: item.uuid,
                              fileExtension: prodUrl.pathExtension,
                              urlAsset: AVURLAsset(url: FileManager.default.fileExists(atPath: url.path) ? url : prodUrl))
        assetPlaybackManager.asset = playbackAsset
        downloadingViewModel.downloadAsset.value = playbackAsset
        userActionsViewModel.playable = item
        
        fullPlayPauseButton.addTarget(self, action: #selector(PopupContentController.doPlayPause), for: .touchUpInside)
        
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(PopupContentController.handleDownloadDidInitiateNotification(notification:)), name: DownloadDataService.fileDownloadDidInitiateNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(PopupContentController.handleDownloadDidProgressNotification(notification:)), name: DownloadDataService.fileDownloadDidProgressNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(PopupContentController.handleDownloadDidCompleteNotification(notification:)), name: DownloadDataService.fileDownloadDidCompleteNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(PopupContentController.handleDownloadDidCancelNotification(notification:)), name: DownloadDataService.fileDownloadDidCancelNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(PopupContentController.handleDownloadDidErrorNotification(notification:)), name: DownloadDataService.fileDownloadDidErrorNotification, object: nil)
        
        resetUIDefaults()
        resetDownloadingViewModel()
        bindUI()
        
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
        
        resetUIBindings()
    }
    
    // MARK: Private
    
    private func resetUIBindings() {
        bag = DisposeBag()
    }
    
    private func resetUIDefaults() {
        dateComponentFormatter.unitsStyle = .positional
        dateComponentFormatter.allowedUnits = [.minute, .second]
        dateComponentFormatter.zeroFormattingBehavior = [.pad]
        
        fullPlaybackSlider.thumbTintColor = UIColor.lightGray //UIColor(red: CGFloat(238/255), green: CGFloat(238/255), blue: CGFloat(238/255), alpha: CGFloat(1))
        
        if let songAttribs: [NSAttributedString.Key : Any] = fullSongNameLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
            fullSongNameLabel.attributedText = NSAttributedString(string: songTitle, attributes: songAttribs)
        }

//        fullSongNameLabel.text = songTitle
        fullSongNameLabel.fadeLength = 10.0
        fullSongNameLabel.speed = .duration(8.0)
        
//        fullAlbumNameLabel.text = albumTitle
        if let albumAttribs: [NSAttributedString.Key : Any] = fullAlbumNameLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
            fullAlbumNameLabel.attributedText = NSAttributedString(string: albumTitle, attributes: albumAttribs)
        }
        fullAlbumNameLabel.fadeLength = 10.0
        fullAlbumNameLabel.speed = .duration(8.0)
        
        fullAlbumArtImageView.layer.shadowColor = UIColor.darkGray.cgColor
        fullAlbumArtImageView.layer.shadowOffset = CGSize(width: 2, height: 4)
        fullAlbumArtImageView.layer.shadowOpacity = 0.8
        fullAlbumArtImageView.layer.shadowRadius = 4.0
//        fullAlbumArtImageView.clipsToBounds = false
        fullAlbumArtImageView.image = albumArt
        
        popupItem.title = songTitle
        popupItem.subtitle = albumTitle
        
        fullDownloadProgress.value = CGFloat(0)
        fullDownloadProgress.style = .ontop
        fullDownloadProgress.innerRingColor = UIColor(red: 21.0/255.0, green: 126.0/255.0, blue: 251.0/255.0, alpha: 1.0)
        fullDownloadProgress.outerRingColor = UIColor(white: 0.8, alpha: 1.0)
        fullDownloadProgress.outerRingWidth = 3.0
        fullDownloadProgress.innerRingWidth = 3.0
        
        // emptyUIState
        
        if let playbackSpeed: Float = UserDefaults.standard.object(forKey: UserPrefs.playbackSpeed.rawValue) as? Float {
            
            DDLogDebug("print rate: \(String(describing:playbackSpeed))")
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
            if let attribs: [NSAttributedString.Key : Any] = fullToggleSpeedButton.currentAttributedTitle?.attributes(at: 0, effectiveRange: nil) {
                fullToggleSpeedButton.setAttributedTitle(NSAttributedString(string: String(describing:playbackSpeed).appending("x"), attributes: attribs), for: .normal)
            }
        }
        
        if let timeAttribs: [NSAttributedString.Key : Any] = fullCurrentPlaybackPositionLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
            fullCurrentPlaybackPositionLabel.attributedText = NSAttributedString(string: "-:--", attributes: timeAttribs)
            fullTotalPlaybackDurationLabel.attributedText = NSAttributedString(string: "-:--", attributes: timeAttribs)
        }

//        fullCurrentPlaybackPositionLabel.text = "-:--"
//        fullTotalPlaybackDurationLabel.text = "-:--"
        fullPlayPauseButton.setImage(UIImage(named: "nowPlaying_play"), for: .normal)
        
        updateTransportUIState()
    }
    
    func resetDownloadingViewModel() {
        //        let filePath: URL = FileSystem.savedDirectory.appendingPathComponent(self.playbackAsset.uuid)
        
        if FileManager.default.fileExists(atPath: FileSystem.savedDirectory.appendingPathComponent(self.playbackAsset.uuid.appending(String(describing: ".\(self.playbackAsset.fileExtension)"))).path) {
            downloadState.value = .complete
            //            downloadImageNameEvent.value = "share-box"
        } else {
            downloadState.value = .initial
            //            downloadImageNameEvent.value = "download_icon_black"
        }
    }
    
    @objc func doPlayPause() {
        assetPlaybackManager.togglePlayPause()
        
        //        updateToolbarItemState()
    }
    
    // MARK: Target-Action Methods
    
    @IBAction func togglePlaybackSpeed(_ sender: Any) {
        var speedTitle: String = "1.0"
        
        //        switch speed {
        if playbackSpeed == .oneX {
            playbackSpeed = .onePointTwoFiveX
            speedTitle = "1.25"
            if let attribs: [NSAttributedString.Key : Any] = fullToggleSpeedButton.currentAttributedTitle?.attributes(at: 0, effectiveRange: nil) {
                fullToggleSpeedButton.setAttributedTitle(NSAttributedString(string: speedTitle.appending("x"), attributes: attribs), for: .normal)
            }

        }
        else if playbackSpeed == .onePointTwoFiveX {
            playbackSpeed = .onePointFiveX
            speedTitle = "1.5"
            if let attribs: [NSAttributedString.Key : Any] = fullToggleSpeedButton.currentAttributedTitle?.attributes(at: 0, effectiveRange: nil) {
                fullToggleSpeedButton.setAttributedTitle(NSAttributedString(string: speedTitle.appending("x"), attributes: attribs), for: .normal)
            }
        }
        else if playbackSpeed == .onePointFiveX {
            playbackSpeed = .oneX
            speedTitle = "1.0"
            if let attribs: [NSAttributedString.Key : Any] = fullToggleSpeedButton.currentAttributedTitle?.attributes(at: 0, effectiveRange: nil) {
                fullToggleSpeedButton.setAttributedTitle(NSAttributedString(string: speedTitle.appending("x"), attributes: attribs), for: .normal)
            }
        }
        if let rate = Float(speedTitle) {
            assetPlaybackManager.playbackRate(rate)
        }
    }
    
    @IBAction func handleUserDidPressBackwardButton(_ sender: Any) {
        if assetPlaybackManager.playbackPosition < 5.0 {
            // If the currently playing asset is less than 5 seconds into playback then skip to the previous `Asset`.
            assetPlaybackManager.previousTrack()
//            resetDownloadingViewModel()
        }
        else {
            // Otherwise seek back to the beginning of the currently playing `Asset`.
            assetPlaybackManager.seekTo(0)
        }
    }
    
    @IBAction func handleUserDidPressForwardButton(_ sender: Any) {
        assetPlaybackManager.nextTrack()
    }
    
    @IBAction func share(sender: AnyObject) {
        // copy file to temp dir to rename it
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        // generate temp file url path
        
        let firstPart: String = "\(self.playbackAsset.artist.replacingOccurrences(of: " ", with: ""))"
        let secondPart: String = "\(self.playbackAsset.name.replacingOccurrences(of: " ", with: "")).mp3"
        let destinationLastPathComponent: String = String(describing: "\(firstPart)-\(secondPart)")
        
        let sourceFileUrl: URL = FileSystem.savedDirectory.appendingPathComponent(self.playbackAsset.uuid.appending(String(describing: ".\(self.playbackAsset.fileExtension)")))
        let temporaryFileURL: URL = temporaryDirectoryURL.appendingPathComponent(destinationLastPathComponent)
        DDLogDebug("temporaryFileURL: \(temporaryFileURL)")
        
        // capture the audio file as a Data blob and then write it
        // to temp dir
        
        do {
            let audioData: Data = try Data(contentsOf: sourceFileUrl, options: .uncached)
            try audioData.write(to: temporaryFileURL, options: .atomicWrite)
        } catch {
            DDLogDebug("error writing temp audio file: \(error)")
            return
        }
        
        let message = MessageWithSubjectActivityItem(subject: String(describing: "\(self.playbackAsset.name) by \(self.playbackAsset.artist)"), message: "Shared via the Faithful Word App: https://faithfulwordapp.com/")
        let itemsToShare: [Any] = [message, temporaryFileURL]
        
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .openInIBooks,
            .print,
            .saveToCameraRoll,
            .postToWeibo,
            .postToFlickr,
            .postToVimeo,
            .postToTencentWeibo]
        
        self.present(activityViewController, animated: true, completion: {})
    }
    
    @objc func updateTransportUIState() {
        guard let pauseImage: UIImage = UIImage(named: "pause"),
            let playImage: UIImage = UIImage(named: "play"),
            let fullPlayImage: UIImage = UIImage(named: "nowPlaying_play"),
            let fullPauseImage: UIImage = UIImage(named: "nowPlaying_pause")
            else { return }
//        DDLogDebug("updateTransportUIState")
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
            
            DDLogDebug("print rate: \(String(describing:playbackSpeed))")
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
            
            if let attribs: [NSAttributedString.Key : Any] = fullToggleSpeedButton.currentAttributedTitle?.attributes(at: 0, effectiveRange: nil) {
                fullToggleSpeedButton.setAttributedTitle(NSAttributedString(string: String(describing:playbackSpeed).appending("x"), attributes: attribs), for: .normal)
            }
        }
        
        if let timeAttribs: [NSAttributedString.Key : Any] = fullCurrentPlaybackPositionLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
            fullCurrentPlaybackPositionLabel.attributedText = NSAttributedString(string: "-:--", attributes: timeAttribs)
            fullTotalPlaybackDurationLabel.attributedText = NSAttributedString(string: "-:--", attributes: timeAttribs)
        }

        fullPlayPauseButton.setImage(UIImage(named: "nowPlaying_play"), for: .normal)
        
        updateTransportUIState()
        
    }
    // MARK: Key-Value Observing Method
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AssetPlaybackManager.duration) {
            let duration: Float = Float(assetPlaybackManager.duration)
            //            DDLogDebug("duration: \(duration)")
            if !duration.isNaN {
                estimatedDuration = duration
                //                DDLogDebug("assetPlaybackManager.duration: \(assetPlaybackManager.duration)")
                fullPlaybackSlider.minimumValue = Float(0)
                fullPlaybackSlider.maximumValue = assetPlaybackManager.duration
            }
            
        }
        else if keyPath == #keyPath(AssetPlaybackManager.playbackPosition) {
            let playbackPosition: Float = Float(assetPlaybackManager.playbackPosition)
            if !playbackPosition.isNaN {
                estimatedPlaybackPosition = playbackPosition
                //                DDLogDebug("assetPlaybackManager.playbackPosition: \(assetPlaybackManager.playbackPosition)")
                guard let stringValue = dateComponentFormatter.string(from: TimeInterval(assetPlaybackManager.playbackPosition)) else { return }
                if let timeAttribs: [NSAttributedString.Key : Any] = fullCurrentPlaybackPositionLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
                    fullCurrentPlaybackPositionLabel.attributedText = NSAttributedString(string: stringValue, attributes: timeAttribs)
                }
                actualPlaybackProgress.value = assetPlaybackManager.playbackPosition
                
                if estimatedDuration != 0 {
                    let remainingTime: Float = Float(estimatedDuration - assetPlaybackManager.playbackPosition)
                    guard let stringValue = dateComponentFormatter.string(from: TimeInterval(remainingTime)) else { return }
                    
                    if let timeAttribs: [NSAttributedString.Key : Any] = fullTotalPlaybackDurationLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
                        fullTotalPlaybackDurationLabel.attributedText = NSAttributedString(string: String("-").appending(stringValue), attributes: timeAttribs)
                    }
                } else {
                    if let timeAttribs: [NSAttributedString.Key : Any] = fullCurrentPlaybackPositionLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
                        fullCurrentPlaybackPositionLabel.attributedText = NSAttributedString(string: "-:--", attributes: timeAttribs)
                        fullTotalPlaybackDurationLabel.attributedText = NSAttributedString(string: "-:--", attributes: timeAttribs)
                    }
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
            if let songAttribs: [NSAttributedString.Key : Any] = fullSongNameLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
                fullSongNameLabel.attributedText = NSAttributedString(string: assetPlaybackManager.asset.name, attributes: songAttribs)
            }
            if let albumAttribs: [NSAttributedString.Key : Any] = fullAlbumNameLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
                fullAlbumNameLabel.attributedText = NSAttributedString(string: assetPlaybackManager.asset.artist, attributes: albumAttribs)
            }
            
            songTitle = assetPlaybackManager.asset.name
            albumTitle = assetPlaybackManager.asset.artist
            
            guard let asset = assetPlaybackManager.asset else {
                return
            }
            
            let urlAsset = asset.urlAsset
            DDLogDebug("urlAsset: \(urlAsset)")
            let artworkData = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common).first?.value as? Data ?? Data()
            
            if let image = UIImage(data: artworkData) {
                albumArt = image
            } else {
                if let image = UIImage(named: "creation") {
                    albumArt = image
                } else {
                    albumArt = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
                }
            }
            
            
            //            fullAlbumArtImageView.image = image
        }
        else {
            
            albumArt = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
            
            if let songAttribs: [NSAttributedString.Key : Any] = fullSongNameLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
                fullSongNameLabel.attributedText = NSAttributedString(string: "--", attributes: songAttribs)
            }
            if let albumAttribs: [NSAttributedString.Key : Any] = fullAlbumNameLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
                fullAlbumNameLabel.attributedText = NSAttributedString(string: "--", attributes: albumAttribs)
            }

            if let timeAttribs: [NSAttributedString.Key : Any] = fullCurrentPlaybackPositionLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
                fullCurrentPlaybackPositionLabel.attributedText = NSAttributedString(string: "-:--", attributes: timeAttribs)
                fullTotalPlaybackDurationLabel.attributedText = NSAttributedString(string: "-:--", attributes: timeAttribs)
            }
            fullPlaybackSlider.value = Float(0)
            
            estimatedPlaybackPosition = Float(0)
            estimatedDuration = Float(0)
            resetUIDefaults()
        }
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
                let presenterName: String = playable.presenterName ?? self.albumTitle,
                let prodUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path)) else { return }
            
            // play local file if available
//            (self.playbackAsset.uuid.appending(String(describing: ".\(self.playbackAsset.fileExtension)")))
            let url: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(playable.uuid.appending(String(describing: ".\(prodUrl.pathExtension)"))).path)
            playbackAsset = Asset(name: localizedName,
                                  artist: presenterName,
                                  uuid: playable.uuid,
                                  fileExtension: prodUrl.pathExtension,
                                  urlAsset: AVURLAsset(url: FileManager.default.fileExists(atPath: url.path) ? url : prodUrl))
            
            assetPlaybackManager.asset = playbackAsset
            downloadingViewModel.downloadAsset.value = playbackAsset
            userActionsViewModel.playable = playable

            
            //reset UI
            resetUIDefaults()
            resetDownloadingViewModel()
            //            bindUI()
            assetPlaybackManager.seekTo(0)
            //            assetPlaybackManager.play()
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
                let presenterName: String = playable.presenterName ?? self.albumTitle,
                let prodUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path)) else { return }
            
            // play local file if available
            let url: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(playable.uuid.appending(String(describing: ".\(prodUrl.pathExtension)"))).path)
            playbackAsset = Asset(name: localizedName,
                                  artist: presenterName,
                                  uuid: playable.uuid,
                                  fileExtension: prodUrl.pathExtension,
                                  urlAsset: AVURLAsset(url: FileManager.default.fileExists(atPath: url.path) ? url : prodUrl))

            assetPlaybackManager.asset = playbackAsset
            downloadingViewModel.downloadAsset.value = playbackAsset
            userActionsViewModel.playable = playable
            
            //reset UI
            resetUIDefaults()
            resetDownloadingViewModel()
            //            bindUI()
            assetPlaybackManager.seekTo(0)
            //            assetPlaybackManager.play()
        }
    }
    
    @objc func handlePlayerRateDidChangeNotification(notification: Notification) {
        DDLogDebug("handlePlayerRateDidChangeNotification notification: \(notification)")
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
    
    @objc func handleDownloadDidInitiateNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            DDLogDebug("initiateNotification filedownload: \(fileDownload)")
            if fileDownload.localUrl.lastPathComponent == self.playbackAsset.uuid.appending(String(describing: ".\(self.playbackAsset.fileExtension)")) {
                
                self.downloadState.value = .initiating
            }
            
        }
    }
    
    @objc func handleDownloadDidProgressNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            DDLogDebug("lastPathComponent: \(fileDownload.localUrl.lastPathComponent) uuid: \(self.playbackAsset.uuid)")
            if fileDownload.localUrl.lastPathComponent == self.playbackAsset.uuid.appending(String(describing: ".\(self.playbackAsset.fileExtension)")) {
                self.fullDownloadProgress.maxValue =  CGFloat(fileDownload.totalCount)
                self.fullDownloadProgress.value = CGFloat(fileDownload.completedCount)
                
                self.downloadState.value = .inProgress
                
                DDLogDebug("fileDownload: \(fileDownload.localUrl) | \(fileDownload.completedCount) / \(fileDownload.totalCount)(\(fileDownload.progress) | \(fileDownload.state))")
            }
        }
    }
    
    @objc func handleDownloadDidCompleteNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            DDLogDebug("completeNotification filedownload: \(fileDownload)")
            if fileDownload.localUrl.lastPathComponent == self.playbackAsset.uuid.appending(String(describing: ".\(self.playbackAsset.fileExtension)")) {
                self.downloadState.value = .complete
            }
        }
    }
    
    @objc func handleDownloadDidErrorNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            DDLogDebug("errorNotification filedownload: \(fileDownload)")
            if fileDownload.localUrl.lastPathComponent == self.playbackAsset.uuid.appending(String(describing: ".\(self.playbackAsset.fileExtension)")) {
                // even though it's an error, just set it back to .initial
                // because we have no use case for an errored download at the moment
                self.downloadState.value = .initial
            }
        }
    }
    
    @objc func handleDownloadDidCancelNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            DDLogDebug("cancelNotification filedownload: \(fileDownload)")
            if fileDownload.localUrl.lastPathComponent == self.playbackAsset.uuid.appending(String(describing: ".\(self.playbackAsset.fileExtension)")) {
                self.downloadState.value = .initial
            }
        }
    }
    
}
