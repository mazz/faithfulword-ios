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
    case onePointFiveX
    case onePointSevenFiveX
    case twoX
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
    @IBOutlet weak var fullDownloadProgress: RPCircularProgress!
    @IBOutlet weak var fullProgressDownloadButton: UIButton!
    @IBOutlet weak var fullProgressShareButton: UIButton!
    
    
    let dateComponentFormatter = DateComponentsFormatter()
    let accessibilityDateComponentsFormatter = DateComponentsFormatter()
    
    // bar
    var playPauseButton: UIBarButtonItem!
    var nextButton: UIBarButtonItem!
    
    // MARK: Fields
    internal var playbackAsset: Asset!
    // the state of the download button image name
    //    public let downloadImageNameEvent = Field<String>("download_icon_black")
    
    var scrubbing: Bool = false
    var playingWhileScrubbing: Bool = false
    
    public var playbackViewModel: PlaybackControlsViewModel!
    public var downloadingViewModel: DownloadViewModel!
    public var userActionsViewModel: UserActionsViewModel!
    
    private let sliderInUse = Variable<Bool>(false)
    
    internal let actualPlaybackProgress = Field<Float>(0)
    internal let estimatedDuration = Field<Float>(0)
    var estimatedPlaybackPosition: Float = Float(0)
    
    private var repeatMode: RepeatSetting = .repeatOff {
        didSet {
            self.fullRepeatButton.setImage((repeatMode == .repeatOne) ? #imageLiteral(resourceName: "repeat-2") : #imageLiteral(resourceName: "repeat"), for: .normal)
        }
    }
    
    private var bag = DisposeBag()
    
    var playbackRepeat : Bool?
    //    var muteVolume : Bool?
    var playbackSpeed: PlaybackSpeed = .oneX
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        playPauseButton = UIBarButtonItem(image: UIImage(named: "play"), style: .plain, target: self, action: #selector(PopupContentController.doPlayPause))
        playPauseButton.accessibilityLabel = NSLocalizedString("Play", comment: "").l10n()
        nextButton = UIBarButtonItem(image: UIImage(named: "nextFwd"), style: .plain, target: self, action: #selector(PopupContentController.handleUserDidPressForwardButton))
        nextButton.accessibilityLabel = NSLocalizedString("Next Track", comment: "").l10n()
        
        popupItem.rightBarButtonItems = [ playPauseButton, nextButton ]
        
    }
    
    func bindPlaybackViewModel() {
        
        playbackViewModel.playDisabled
            .asObservable()
            .observeOn(MainScheduler.instance)
            .next { [unowned self] playDisabled in
                self.playPauseButton.isEnabled = !playDisabled
                self.fullPlayPauseButton.isEnabled = !playDisabled
                self.fullToggleSpeedButton.isEnabled = !playDisabled
        }
        .disposed(by: bag)
        
        playbackViewModel.playbackState
            .asObservable()
            .observeOn(MainScheduler.instance)
            .next { [unowned self] playbackState in
                guard let pauseImage: UIImage = UIImage(named: "pause"),
                    let playImage: UIImage = UIImage(named: "play"),
                    let fullPlayImage: UIImage = UIImage(named: "nowPlaying_play"),
                    let fullPauseImage: UIImage = UIImage(named: "nowPlaying_pause") else { return }

                let accessibilityPlay: String = NSLocalizedString("Play", comment: "").l10n()
                let accessibilityPause: String = NSLocalizedString("Pause", comment: "").l10n()
                switch playbackState {
                    
                case .initial:
                    self.playPauseButton.image = playImage
                    self.playPauseButton.accessibilityLabel = accessibilityPlay
                    
                    self.fullPlayPauseButton.setImage(fullPlayImage, for: .normal)
                    self.fullPlayPauseButton.accessibilityLabel = accessibilityPlay
                case .playing:
                    self.playPauseButton.image = pauseImage
                    self.playPauseButton.accessibilityLabel = accessibilityPause

                    self.fullPlayPauseButton.setImage(fullPauseImage, for: .normal)
                    self.fullPlayPauseButton.accessibilityLabel = accessibilityPause
                case .paused:
                    self.playPauseButton.image = playImage
                    self.playPauseButton.accessibilityLabel = accessibilityPlay

                    self.fullPlayPauseButton.setImage(fullPlayImage, for: .normal)
                    self.fullPlayPauseButton.accessibilityLabel = accessibilityPlay
                case .interrupted:
                    self.playPauseButton.image = playImage
                    self.playPauseButton.accessibilityLabel = accessibilityPlay

                    self.fullPlayPauseButton.setImage(fullPlayImage, for: .normal)
                    self.fullPlayPauseButton.accessibilityLabel = accessibilityPlay
                }
            }
            .disposed(by: bag)
        
        // playbackViewModel.playbackPlayable could either be a Playable or
        // a UserActionPlayable depending upon whether it was found in the
        // useractionplayable db table
        playbackViewModel.playbackPlayable
            .asObservable()
            .observeOn(MainScheduler.instance)
            .filterNils()
            .next { [unowned self] playable in
                guard let path: String = playable.path,
                    let selectedPlayable: Playable = self.playbackViewModel.selectedPlayable.value,
                    let localizedName: String = playable.localizedname,
                    let presenterName: String = playable.presenterName ?? "Unknown",
                    let percentEncoded: String = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                    let prodUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(percentEncoded)) else { return }

                let url: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(selectedPlayable.uuid.appending(String(describing: ".\(prodUrl.pathExtension)"))).path)
                
                var playbackPosition: Double = 0
                var playableUuid: String = playable.uuid
                if let historyPlayable: UserActionPlayable = playable as? UserActionPlayable {
//                if let historyPlayable: UserActionPlayable = playable as? UserActionPlayable,
//                    historyPlayable.mediaCategory == "preaching" {
                    playbackPosition = historyPlayable.playbackPosition
                    playableUuid = historyPlayable.playableUuid
                }
                
                var playbackRate: Float = 1.0
                if let playbackSpeed: Float = UserDefaults.standard.object(forKey: UserPrefs.playbackSpeed.rawValue) as? Float {
                    playbackRate = playbackSpeed
                }
                
                DDLogDebug("Asset playableUuid: \(playableUuid)")

                self.playbackAsset = Asset(name: localizedName,
                                      artist: presenterName,
                                      uuid: playableUuid,
                                      fileExtension: prodUrl.pathExtension,
                                      playbackPosition: playbackPosition,
                                      playbackRate: playbackRate,
                                      urlAsset: AVURLAsset(url: FileManager.default.fileExists(atPath: url.path) ? url : prodUrl))

                self.playbackViewModel.pausePlayback()
                self.playbackViewModel.assetPlaybackService.assetPlaybackManager.asset = self.playbackAsset

                self.downloadingViewModel.downloadAssetIdentifier.value = self.playbackAsset.uuid.appending(String(describing: ".\(self.playbackAsset.fileExtension)"))
                self.downloadingViewModel.downloadAssetRemoteUrlString.value = self.playbackAsset.urlAsset.url.absoluteString
                
                // pretty sure we can depend on selectedPlayable to be ready
                
                if let selectedPlayable: Playable = self.playbackViewModel.selectedPlayable.value {
                    self.downloadingViewModel.downloadAssetPlaylistUuid.value = selectedPlayable.playlistUuid
                }

                // do not pass-in UserActionPlayable to historyservice or the playable.uuid and useractionplayable.playableUuid's will
                // get mixed-up
                self.userActionsViewModel.playable = selectedPlayable
                
                
                // initiate the check if we have downloaded the content for this playable before
                // if it's nil we never downloaded it before so send .initial
                // otherwise just passthrough
                self.downloadingViewModel.storedFileDownload(for: playableUuid)
                    .asObservable()
                    .take(1)
                    .subscribe(onNext: { fileDownload in
                        if let download: FileDownload = fileDownload {
                            self.downloadingViewModel.downloadState.onNext(download.state)
                        } else {
                            self.downloadingViewModel.downloadState.onNext(.initial)
                        }
                    })
                    .disposed(by: self.bag)
                
            }
            .disposed(by: bag)
        
        playbackViewModel.songTitle
            .asObservable()
            .do(onNext: { [unowned self] songNameAttr in
                self.popupItem.title = songNameAttr.string
            })
            .bind(to: fullSongNameLabel.rx.attributedText)
            .disposed(by: bag)

        playbackViewModel.artistName
            .asObservable()
            .do(onNext: { [unowned self] artistNameAttr in
                self.popupItem.subtitle = artistNameAttr.string
            })
            .bind(to: fullAlbumNameLabel.rx.attributedText)
            .disposed(by: bag)
        
        playbackViewModel.albumArt
            .asObservable()
            .do(onNext: { [unowned self] albumArtImage in
                self.popupItem.image = albumArtImage
                self.popupItem.accessibilityImageLabel = NSLocalizedString("Album Art", comment: "").l10n()
            })
            .filterNils()
            .bind(to: fullAlbumArtImageView.rx.image)
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
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(to: playbackViewModel.sliderScrubEvent)
            .disposed(by: bag)
        fullPlaybackSlider.isContinuous = true
        fullPlaybackSlider.isMultipleTouchEnabled = false
        
        // check to update the slider position around every 0.4 seconds
        // as long as the user is not scrubbing
        actualPlaybackProgress.asObservable()
            .observeOn(MainScheduler.instance)
            .filter { [unowned self] _ in !self.sliderInUse.value }
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] progress in
                self.fullPlaybackSlider.value = progress
                DDLogDebug("field progress: \(progress)")
            })
            .disposed(by: bag)
        
        listenForSliderUserEvents()
        
//        actualPlaybackProgress.asObservable()
//            .observeOn(MainScheduler.instance)
//            .bind(to: userActionsViewModel.progressEvent)
//            .disposed(by: bag)
        
        userActionsViewModel.playbackHistory
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { playable in
                DDLogDebug("top playable: \(playable.first)")
            })
            .disposed(by: bag)

        // combine playback events with duration calculation so that we can store the
        // duration. We need duration because we need to determine whether or not to
        // resume playback of long content like preaching
        Observable.combineLatest(actualPlaybackProgress.asObservable(), estimatedDuration.asObservable())
            .observeOn(MainScheduler.instance)
            .bind(to: userActionsViewModel.playbackEvent)
            .disposed(by: self.bag)
    }
    
    func bindDownloadingViewModel() {
        
        // hide progress button on completion or initial
//        downloadingViewModel.downloadState.asObservable()
//            .observeOn(MainScheduler.instance)
//            .map { fileDownloadState in fileDownloadState != .inProgress }
//            .bind(to: fullDownloadProgress.rx.isHidden)
//            .disposed(by: bag)
        
        
//        downloadingViewModel.downloadInProgress.asObservable()
//            .observeOn(MainScheduler.instance)
//            .map { !$0 }
//            .bind(to: fullDownloadProgress.rx.isHidden)
//            .disposed(by: bag)

        downloadingViewModel.downloadNotStarted.asObservable()
            .observeOn(MainScheduler.instance)
            .next { [weak self] downloadNotStarted in
                if let weakSelf = self {
                    // user tapped, download beginning
                    if downloadNotStarted == true {
                        weakSelf.fullDownloadProgress.isHidden = true
                        weakSelf.fullProgressDownloadButton.isHidden = true
                        weakSelf.fullDownloadButton.isHidden = false
                        weakSelf.fullProgressShareButton.isHidden = true
                        
//                        weakSelf.fullDownloadProgress.indeterminateProgress = 0.5
//                        weakSelf.fullDownloadProgress.enableIndeterminate() //value = CGFloat(100)


                        //                        weakSelf.fullDownloadProgress.value = CGFloat(100)
//                        weakSelf.fullDownloadProgress.style = .ontop
                    }
                }
            }
            .disposed(by: bag)

        downloadingViewModel.downloadStarting.asObservable()
            .observeOn(MainScheduler.instance)
            .next { [weak self] downloadStarting in
                if let weakSelf = self {
                    // user tapped, download beginning
                    if downloadStarting == true {
                        weakSelf.fullDownloadProgress.isHidden = false
                        weakSelf.fullDownloadProgress.indeterminateProgress = 0.5
                        weakSelf.fullDownloadProgress.enableIndeterminate() //value = CGFloat(100)
//                        weakSelf.fullDownloadProgress.style = .dotted
                        
                        weakSelf.fullProgressDownloadButton.isHidden = false
                        weakSelf.fullDownloadButton.isHidden = true
                        weakSelf.fullProgressShareButton.isHidden = true
                        
                    }
                }
            }
            .disposed(by: bag)

        downloadingViewModel.downloadInProgress.asObservable()
            .observeOn(MainScheduler.instance)
            .next { [weak self] downloadInProgress in
                if let weakSelf = self {
                    // user tapped, download beginning
                    if downloadInProgress == true {
                        weakSelf.fullDownloadProgress.isHidden = false
                        weakSelf.fullProgressDownloadButton.isHidden = false
                        weakSelf.fullDownloadButton.isHidden = true
                        weakSelf.fullProgressShareButton.isHidden = true

//                        weakSelf.fullDownloadProgress.value = CGFloat(100)
                        weakSelf.fullDownloadProgress.enableIndeterminate(false, completion: nil)
                    }
                }
            }
            .disposed(by: bag)
        
        downloadingViewModel.completedDownload.asObservable()
            .observeOn(MainScheduler.instance)
            .next { [weak self] completedDownload in
                if let weakSelf = self {
                    // user tapped, download beginning
                    if completedDownload == true {
                        weakSelf.fullDownloadProgress.isHidden = true
                        weakSelf.fullProgressDownloadButton.isHidden = true
                        weakSelf.fullDownloadButton.isHidden = true
                        weakSelf.fullProgressShareButton.isHidden = false
                        
                        //                        weakSelf.fullDownloadProgress.value = CGFloat(100)
//                        weakSelf.fullDownloadProgress.ena
                    }
                }
            }
            .disposed(by: bag)


        // hide progress stop button on completion or initial
//        downloadingViewModel.downloadState.asObservable()
//            .observeOn(MainScheduler.instance)
//            .map { fileDownloadState in fileDownloadState != .inProgress }
//            .bind(to: fullProgressDownloadButton.rx.isHidden)
//            .disposed(by: bag)
        
//        downloadingViewModel.downloadInProgress.asObservable()
//            .observeOn(MainScheduler.instance)
//            .map { !$0 }
//            .bind(to: fullProgressDownloadButton.rx.isHidden)
//            .disposed(by: bag)

        
        // hide download button during download
        //        downloadState.asObservable()
        //            .observeOn(MainScheduler.instance)
        //            .map { fileDownloadState in fileDownloadState == .inProgress }
        //            .bind(to: fullDownloadButton.rx.isHidden)
        //            .disposed(by: bag)
        
        // hide download button if download complete
//        downloadingViewModel.downloadState.asObservable()
//            .observeOn(MainScheduler.instance)
//            .map { fileDownloadState in fileDownloadState != .initial }
//            .bind(to: fullDownloadButton.rx.isHidden)
//            .disposed(by: bag)
        
//        downloadingViewModel.downloadNotStarted.asObservable()
//            .observeOn(MainScheduler.instance)
//            .map { !$0 }
//            .bind(to: fullDownloadButton.rx.isHidden)
//            .disposed(by: bag)

        // hide share button if not downloaded yet
//        downloadingViewModel.downloadState.asObservable()
//            .observeOn(MainScheduler.instance)
//            .map { fileDownloadState in fileDownloadState != .complete }
//            .bind(to: fullProgressShareButton.rx.isHidden)
//            .disposed(by: bag)

        
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
        
        resetViewModelsBag()

        bindPlaybackViewModel()
        bindDownloadingViewModel()

        // assetPlaybackService.playableItem should be valid pointer
        // because it should be set when the user taps a row in MediaListingViewModel

/*
//        guard let assetPlaybackService = playbackViewModel.assetPlaybackService,
        guard let item: Playable = playbackViewModel.assetPlaybackService.playableItem.value,
            let path: String = item.path,
            let localizedName: String = item.localizedName,
            let presenterName: String = item.presenterName ?? "Unknown",
            let prodUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path))
            else { return }
*/
        // Add the Key-Value Observers needed to keep the UI up to date.
        //            assetPlaybackManager.addObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.percentProgress), options: NSKeyValueObservingOptions.new, context: nil)
        playbackViewModel.assetPlaybackService.assetPlaybackManager.addObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.duration), options: NSKeyValueObservingOptions.new, context: nil)
        playbackViewModel.assetPlaybackService.assetPlaybackManager.addObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.playbackPosition), options: NSKeyValueObservingOptions.new, context: nil)
        
        // Add the notification observers needed to respond to events from the `AssetPlaybackManager`.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(PopupContentController.handleCurrentAssetDidChangeNotification(notification:)), name: AssetPlaybackManager.currentAssetDidChangeNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PopupContentController.handlePlayerRateDidChangeNotification(notification:)), name: AssetPlaybackManager.playerRateDidChangeNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(PopupContentController.handleAVPlayerItemDidPlayToEndTimeNotification(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)

        
        notificationCenter.addObserver(self, selector: #selector(PopupContentController.handleDownloadDidProgressNotification(notification:)), name: DownloadService.fileDownloadDidProgressNotification, object: nil)

//        self.assetPlaybackManager = playbackViewModel.assetPlaybackService.assetPlaybackManager

/*
         // stop because there could an asset currently playing
         playbackViewModel.assetPlaybackService.assetPlaybackManager.stop()
        
        // play local file if available
        let url: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(item.uuid.appending(String(describing: ".\(prodUrl.pathExtension)"))).path)
        playbackAsset = Asset(name: localizedName,
                              artist: presenterName,
                              uuid: item.uuid,
                              fileExtension: prodUrl.pathExtension,
                              urlAsset: AVURLAsset(url: FileManager.default.fileExists(atPath: url.path) ? url : prodUrl))
        playbackViewModel.assetPlaybackService.assetPlaybackManager.asset = playbackAsset
        downloadingViewModel.downloadAsset.value = playbackAsset
        userActionsViewModel.playable = item
 
 */
        fullPlayPauseButton.addTarget(self, action: #selector(PopupContentController.doPlayPause), for: .touchUpInside)
        
//        let notificationCenter = NotificationCenter.default
        
//        resetUIDefaults()
//        resetDownloadingViewModel()
        dateComponentFormatter.unitsStyle = .positional
        dateComponentFormatter.allowedUnits = [.minute, .second]
        dateComponentFormatter.zeroFormattingBehavior = [.pad]
        
//        fullPlaybackSlider.thumbTintColor = UIColor.lightGray //UIColor(red: CGFloat(238/255), green: CGFloat(238/255), blue: CGFloat(238/255), alpha: CGFloat(1))
        fullSongNameLabel.fadeLength = 10.0
        fullSongNameLabel.speed = .duration(8.0)
        
        fullAlbumNameLabel.fadeLength = 10.0
        fullAlbumNameLabel.speed = .duration(8.0)
        
        fullAlbumArtImageView.layer.shadowColor = UIColor.darkGray.cgColor
        fullAlbumArtImageView.layer.shadowOffset = CGSize(width: 2, height: 4)
        fullAlbumArtImageView.layer.shadowOpacity = 0.8
        fullAlbumArtImageView.layer.shadowRadius = 4.0
        fullAlbumArtImageView.image = popupItem.image
        
        fullDownloadProgress.updateProgress(0.0)
        fullDownloadProgress.trackTintColor = UIColor.init(red: 74 / 255, green: 144 / 255, blue: 226 / 255, alpha: 0.3)
        fullDownloadProgress.progressTintColor = UIColor.init(red: 74 / 255, green: 144 / 255, blue: 226 / 255, alpha: 1)
        fullDownloadProgress.roundedCorners = false
        fullDownloadProgress.thicknessRatio = 0.2

//        fullDownloadProgress.style = .ontop
//        fullDownloadProgress.innerRingColor = UIColor(red: 21.0/255.0, green: 126.0/255.0, blue: 251.0/255.0, alpha: 1.0)
//        fullDownloadProgress.outerRingColor = UIColor(white: 0.8, alpha: 1.0)
//        fullDownloadProgress.outerRingWidth = 3.0
//        fullDownloadProgress.innerRingWidth = 3.0
        
        if let playbackSpeed: Float = UserDefaults.standard.object(forKey: UserPrefs.playbackSpeed.rawValue) as? Float {
            
            DDLogDebug("print rate: \(String(describing:playbackSpeed))")
            switch playbackSpeed {
            case 1.0:
                self.playbackSpeed = .oneX
            case 1.5:
                self.playbackSpeed = .onePointFiveX
            case 1.75:
                self.playbackSpeed = .onePointSevenFiveX
            case 2.0:
                self.playbackSpeed = .twoX
            default:
                self.playbackSpeed = .oneX
            }
            if let attribs: [NSAttributedString.Key : Any] = fullToggleSpeedButton.currentAttributedTitle?.attributes(at: 0, effectiveRange: nil) {
                fullToggleSpeedButton.setAttributedTitle(NSAttributedString(string: String(describing:playbackSpeed).appending("x"), attributes: attribs), for: .normal)
            }
        }


    }
    
    deinit {
        // Remove all KVO and notification observers.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.currentAssetDidChangeNotification, object: nil)
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.previousTrackNotification, object: nil)
//        notificationCenter.removeObserver(self, name: AssetPlaybackManager.nextTrackNotification, object: nil)
        notificationCenter.removeObserver(self, name: AssetPlaybackManager.playerRateDidChangeNotification, object: nil)
        
        //        assetPlaybackManager.removeObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.percentProgress))
        playbackViewModel.assetPlaybackService.assetPlaybackManager.removeObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.duration))
        playbackViewModel.assetPlaybackService.assetPlaybackManager.removeObserver(self, forKeyPath: #keyPath(AssetPlaybackManager.playbackPosition))
        
        resetViewModelsBag()
    }
    
    // MARK: Private
    
    private func resetViewModelsBag() {
        bag = DisposeBag()
    }
    
    @objc func doPlayPause() {
        playbackViewModel.togglePlayPause()
        
        //        updateToolbarItemState()
    }
    
    // MARK: Target-Action Methods
    
    @IBAction func togglePlaybackSpeed(_ sender: Any) {
        var speedTitle: String = "1.0"
        
        //        switch speed {
        if playbackSpeed == .oneX {
            playbackSpeed = .onePointFiveX
            speedTitle = "1.5"
            if let attribs: [NSAttributedString.Key : Any] = fullToggleSpeedButton.currentAttributedTitle?.attributes(at: 0, effectiveRange: nil) {
                fullToggleSpeedButton.setAttributedTitle(NSAttributedString(string: speedTitle.appending("x"), attributes: attribs), for: .normal)
                UserDefaults.standard.set(1.5, forKey: UserPrefs.playbackSpeed.rawValue)
            }

        }
        else if playbackSpeed == .onePointFiveX {
            playbackSpeed = .onePointSevenFiveX
            speedTitle = "1.75"
            if let attribs: [NSAttributedString.Key : Any] = fullToggleSpeedButton.currentAttributedTitle?.attributes(at: 0, effectiveRange: nil) {
                fullToggleSpeedButton.setAttributedTitle(NSAttributedString(string: speedTitle.appending("x"), attributes: attribs), for: .normal)
                UserDefaults.standard.set(1.75, forKey: UserPrefs.playbackSpeed.rawValue)
            }
        }
        else if playbackSpeed == .onePointSevenFiveX {
            playbackSpeed = .twoX
            speedTitle = "2.0"
            if let attribs: [NSAttributedString.Key : Any] = fullToggleSpeedButton.currentAttributedTitle?.attributes(at: 0, effectiveRange: nil) {
                fullToggleSpeedButton.setAttributedTitle(NSAttributedString(string: speedTitle.appending("x"), attributes: attribs), for: .normal)
                UserDefaults.standard.set(2.0, forKey: UserPrefs.playbackSpeed.rawValue)
            }
        }
        else if playbackSpeed == .twoX {
            playbackSpeed = .oneX
            speedTitle = "1.0"
            if let attribs: [NSAttributedString.Key : Any] = fullToggleSpeedButton.currentAttributedTitle?.attributes(at: 0, effectiveRange: nil) {
                fullToggleSpeedButton.setAttributedTitle(NSAttributedString(string: speedTitle.appending("x"), attributes: attribs), for: .normal)
                UserDefaults.standard.set(1.0, forKey: UserPrefs.playbackSpeed.rawValue)
            }
        }
        if let rate = Float(speedTitle) {
            playbackViewModel.updatePlaybackRate(rate)
        }
    }
    
    @IBAction func handleUserDidPressBackwardButton(_ sender: Any) {
//        if playbackViewModel.assetPlaybackService.assetPlaybackManager.playbackPosition < 5.0 {
            // If the currently playing asset is less than 5 seconds into playback then skip to the previous `Asset`.
            playbackViewModel.previousTrack()
//            resetDownloadingViewModel()
//        }
//        else {
//            // Otherwise seek back to the beginning of the currently playing `Asset`.
//            playbackViewModel.assetPlaybackService.assetPlaybackManager.seekTo(0)
//        }
    }
    
    @IBAction func handleUserDidPressForwardButton(_ sender: Any) {
        playbackViewModel.nextTrack()
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
    
    // MARK: Key-Value Observing Method
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AssetPlaybackManager.duration) {
            let duration: Float = Float(playbackViewModel.assetPlaybackService.assetPlaybackManager.duration)
            //            DDLogDebug("duration: \(duration)")
            if !duration.isNaN {
                estimatedDuration.value = duration
                //                DDLogDebug("assetPlaybackManager.duration: \(assetPlaybackManager.duration)")
                fullPlaybackSlider.minimumValue = Float(0)
                fullPlaybackSlider.maximumValue = playbackViewModel.assetPlaybackService.assetPlaybackManager.duration
            }
            
        }
        else if keyPath == #keyPath(AssetPlaybackManager.playbackPosition) {
            let playbackPosition: Float = Float(playbackViewModel.assetPlaybackService.assetPlaybackManager.playbackPosition)
            if !playbackPosition.isNaN {
                estimatedPlaybackPosition = playbackPosition
                //                DDLogDebug("assetPlaybackManager.playbackPosition: \(assetPlaybackManager.playbackPosition)")
                guard let stringValue = dateComponentFormatter.string(from: TimeInterval(playbackViewModel.assetPlaybackService.assetPlaybackManager.playbackPosition)) else { return }
                if let timeAttribs: [NSAttributedString.Key : Any] = fullCurrentPlaybackPositionLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
                    fullCurrentPlaybackPositionLabel.attributedText = NSAttributedString(string: stringValue, attributes: timeAttribs)
                }
                actualPlaybackProgress.value = playbackViewModel.assetPlaybackService.assetPlaybackManager.playbackPosition
                
                if estimatedDuration.value != 0 {
                    let remainingTime: Float = Float(estimatedDuration.value - playbackViewModel.assetPlaybackService.assetPlaybackManager.playbackPosition)
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
        if playbackViewModel.assetPlaybackService.assetPlaybackManager.asset == nil {
//            albumArt = UIColor.lightGray.image(size: CGSize(width: 128, height: 128))
            
            if let timeAttribs: [NSAttributedString.Key : Any] = fullCurrentPlaybackPositionLabel.attributedText?.attributes(at: 0, effectiveRange: nil) {
                fullCurrentPlaybackPositionLabel.attributedText = NSAttributedString(string: "-:--", attributes: timeAttribs)
                fullTotalPlaybackDurationLabel.attributedText = NSAttributedString(string: "-:--", attributes: timeAttribs)
            }
            fullPlaybackSlider.value = Float(0)
            
            estimatedPlaybackPosition = Float(0)
            estimatedDuration.value = Float(0)
//            resetUIDefaults()
        }
    }
    
    
    @objc func handlePlayerRateDidChangeNotification(notification: Notification) {
        DDLogDebug("handlePlayerRateDidChangeNotification notification: \(notification)")
//        updateTransportUIState()
    }
    
    @objc func handleAVPlayerItemDidPlayToEndTimeNotification(notification: Notification) {
        if self.repeatMode == .repeatOff {
            //            self.handleRemoteCommandNextTrackNotification(notification: notification)
            NotificationCenter.default.post(name: AssetPlaybackManager.nextTrackNotification, object: nil, userInfo: [Asset.uuidKey: playbackAsset.uuid])
        } else if self.repeatMode == .repeatOne {
            playbackViewModel.seekTo(0)
            playbackViewModel.playPlayback()
        }
    }
    
    @objc func handleDownloadDidProgressNotification(notification: Notification) {
//        DispatchQueue.main.async { [weak self] in
//            print("notification: \(notification)")
            if let fileDownload: FileDownload = notification.object as? FileDownload,
                let playbackAsset = self.playbackAsset
            {
                print("lastPathComponent: \(fileDownload.localUrl.lastPathComponent) uuid: \(playbackAsset.uuid)")
                if fileDownload.localUrl.lastPathComponent == playbackAsset.uuid.appending(String(describing: ".\(playbackAsset.fileExtension)")) {
//                    self.fullDownloadProgress.maxValue =  CGFloat(fileDownload.totalCount)
//                    self.fullDownloadProgress.value = CGFloat(fileDownload.completedCount)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                        self.fullDownloadProgress.updateProgress(CGFloat(fileDownload.completedCount)/CGFloat(fileDownload.totalCount), completion: {
                            self.fullDownloadProgress.enableIndeterminate(false)
                        })
                    }
                    
                    print("fileDownload: \(fileDownload.localUrl) | \(fileDownload.completedCount) / \(fileDownload.totalCount)(\(fileDownload.progress) | \(fileDownload.state))")
                }
            }
//        }
    }
}
