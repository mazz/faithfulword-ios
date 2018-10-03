//
//  PopupContentController.swift
//

import UIKit
import LNPopupController
import AVFoundation
import RxSwift
import RxCocoa
import MarqueeLabel

class PopupContentController: UIViewController {

    @IBOutlet weak var songNameLabel: MarqueeLabel!
    @IBOutlet weak var albumNameLabel: MarqueeLabel!
    @IBOutlet weak var fullPlayPauseButton: UIButton!
    @IBOutlet weak var fullPlaybackSlider: UISlider!

    @IBOutlet weak var fullAlbumArtImageView: UIImageView!

    @IBOutlet weak var fullCurrentPlaybackPositionLabel: UILabel!
    @IBOutlet weak var fullTotalPlaybackDurationLabel: UILabel!

    var estimatedPlaybackPosition: Float = Float(0)
    var estimatedDuration: Float = Float(0)

    let dateComponentFormatter = DateComponentsFormatter()
    let accessibilityDateComponentsFormatter = DateComponentsFormatter()

    // bar
    var playPauseButton: UIBarButtonItem!
    var nextButton: UIBarButtonItem!

    public var playbackAsset: Asset!
    public var playlistAssets = [Asset]()

    // MARK: Fields
    var scrubbing: Bool = false
    var playingWhileScrubbing: Bool = false

    public var viewModel: PopupContentViewModel!

    private let sliderInUse = Variable<Bool>(false)

//    private let sliderInUse = BehaviorSubject<Bool>(value: false) //ReplaySubject<Bool>.create(bufferSize: 1) //Field<Bool>(false)
    public let actualPlaybackProgress = Field<Float>(0)

    private var bag = DisposeBag()

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
        }
    }

    var songTitle: String = "" {
        didSet {
            if isViewLoaded {
                songNameLabel.text = songTitle
            }

            popupItem.title = songTitle
        }
    }
    var albumTitle: String = "" {
        didSet {
            if isViewLoaded {
                albumNameLabel.text = albumTitle
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

        fullPlaybackSlider.rx.value.asObservable()
            .map { Float($0) }
            .do(onNext: { time in
                print("time: \(time)")
            })
            .distinctUntilChanged()
            .throttle(0.3, scheduler: MainScheduler.instance)
            .bind(to: viewModel.sliderScrubEvent)
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

        guard let assetPlaybackService = viewModel.assetPlaybackService else { return }
        self.assetPlaybackManager = assetPlaybackService.assetPlaybackManager

        bindUI()

        dateComponentFormatter.unitsStyle = .positional
        dateComponentFormatter.allowedUnits = [.minute, .second]
        dateComponentFormatter.zeroFormattingBehavior = [.pad]

        fullPlaybackSlider.thumbTintColor = UIColor.darkGray

        fullPlayPauseButton.addTarget(self, action: #selector(PopupContentController.doPlayPause), for: .touchUpInside)

        songNameLabel.text = songTitle
        songNameLabel.fadeLength = 10.0
        songNameLabel.speed = .duration(8.0)

        albumNameLabel.text = albumTitle
        albumNameLabel.fadeLength = 10.0
        albumNameLabel.speed = .duration(8.0)
//        fullAlbumArtImageView.image = albumArt

        popupItem.title = songTitle
        popupItem.subtitle = albumTitle

        // Add the notification observers needed to respond to events from the `AssetPlaybackManager`.
//        let notificationCenter = NotificationCenter.default
//
//        notificationCenter.addObserver(self, selector: #selector(DemoMusicPlayerController.handleRemoteCommandNextTrackNotification(notification:)), name: AssetPlaybackManager.nextTrackNotification, object: nil)
//        notificationCenter.addObserver(self, selector: #selector(DemoMusicPlayerController.handleRemoteCommandPreviousTrackNotification(notification:)), name: AssetPlaybackManager.previousTrackNotification, object: nil)

        assetPlaybackManager.stop()
        assetPlaybackManager.asset = playbackAsset
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
        guard let playbackService = viewModel.assetPlaybackService,
        let pauseImage: UIImage = UIImage(named: "pause"),
        let playImage: UIImage = UIImage(named: "play"),
        let fullPlayImage: UIImage = UIImage(named: "nowPlaying_play"),
        let fullPauseImage: UIImage = UIImage(named: "nowPlaying_pause")
        else {
            return
        }

        let accessibilityPlay: String = NSLocalizedString("Play", comment: "")
        let accessibilityPause: String = NSLocalizedString("Pause", comment: "")

        if playbackService.assetPlaybackManager.state == .playing {
            playPauseButton.image = playImage
            playPauseButton.accessibilityLabel = accessibilityPlay

            fullPlayPauseButton.setImage(fullPlayImage, for: .normal)
            fullPlayPauseButton.accessibilityLabel = accessibilityPlay

        } else if playbackService.assetPlaybackManager.state == .paused {
            playPauseButton.image = pauseImage
            playPauseButton.accessibilityLabel = accessibilityPause

            fullPlayPauseButton.setImage(fullPauseImage, for: .normal)
            fullPlayPauseButton.accessibilityLabel = accessibilityPause
        }

        playbackService.assetPlaybackManager.togglePlayPause()

//    assetPlaybackManager.asset = Asset(assetName: "Psalm2-DD", urlAsset: AVURLAsset(url: URL(string: "https://d2v5mbm9qwqitj.cloudfront.net/bible/en/0019-0002-Psalms-en.mp3")!))
    }

    // MARK: Target-Action Methods

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



    @objc func updateToolbarItemState() {
        print("updateToolbarItemState")
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
            songNameLabel.text = assetPlaybackManager.asset.assetName
            albumNameLabel.text = assetPlaybackManager.asset.artist

            songTitle = assetPlaybackManager.asset.assetName
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
            songNameLabel.text = "Select Item Below to play"
            fullTotalPlaybackDurationLabel.text = "-:--"
            fullCurrentPlaybackPositionLabel.text = "-:--"
            fullPlaybackSlider.value = Float(0)

            estimatedPlaybackPosition = Float(0)
            estimatedDuration = Float(0)

//            assetListTableView.deselectAll(nil)
        }

        updateToolbarItemState()
    }

    @objc func handleRemoteCommandNextTrackNotification(notification: Notification) {
        guard let assetName = notification.userInfo?[Asset.nameKey] as? String else { return }
        guard let assetIndex = playlistAssets.index(where: {$0.assetName == assetName}) else { return }

        if assetIndex < playlistAssets.count - 1 {
            assetPlaybackManager.asset = playlistAssets[assetIndex + 1]
        }
    }

    @objc func handleRemoteCommandPreviousTrackNotification(notification: Notification) {
        guard let assetName = notification.userInfo?[Asset.nameKey] as? String else { return }
        guard let assetIndex = playlistAssets.index(where: {$0.assetName == assetName}) else { return }

        if assetIndex > 0 {
            assetPlaybackManager.asset = playlistAssets[assetIndex - 1]
        }
    }

    @objc func handlePlayerRateDidChangeNotification(notification: Notification) {
        updateToolbarItemState()
    }

}
