import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import XLActionController
import MagazineLayout

/// Add service screen
public final class MediaListingViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewModelSections.count == 0 {
            return 0
        }
        return viewModelSections[section].items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        
//        if viewModelSections[0].items.count > 0 {
//        DDLogDebug("viewModelSections[indexPath.section].items[indexPath.row]: \(viewModelSections[indexPath.section].items[indexPath.row])")
//        }
        let item: MediaListingItemType = viewModelSections[indexPath.section].items[indexPath.row]
    
        switch item {
        case let .drillIn(enumPlayable, iconName, title, presenter, showBottomSeparator, showAmountDownloaded):
            let drillInCell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaItemCell.description(), for: indexPath) as! MediaItemCell
            switch enumPlayable {
                
            case .playable(let item):
                drillInCell.set(uuid: item.uuid, title: title, presenter: presenter, showBottomSeparator: showBottomSeparator, showAmountDownloaded: showAmountDownloaded)
                
                if let fileDownload: FileDownload = downloadingItems[item.uuid] {
                    
                    drillInCell.progressView.isHidden = false
                    drillInCell.amountDownloaded.isHidden = false
                    drillInCell.amountDownloaded.text = ""
                    
                    switch fileDownload.state {
                    case .initial:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = true
                        drillInCell.amountDownloaded.text = ""
                    case .initiating:
                        drillInCell.progressView.isHidden = false
                        drillInCell.progressView.progress = fileDownload.progress
                        
                        drillInCell.amountDownloaded.isHidden = false
                        drillInCell.amountDownloaded.text = ""
                    case .inProgress:
                        drillInCell.progressView.progress = fileDownload.progress
                        drillInCell.amountDownloaded.text = fileDownload.extendedDescription
                    case .cancelling:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = true
                        drillInCell.amountDownloaded.text = ""
                    case .cancelled:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = true
                        drillInCell.amountDownloaded.text = ""
                    case .complete:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = true
                        drillInCell.amountDownloaded.text = ""
                    case .error:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = false
                        drillInCell.amountDownloaded.text = fileDownload.extendedDescription
                    case .unknown:
                        drillInCell.progressView.isHidden = true
                        drillInCell.amountDownloaded.isHidden = true
                        drillInCell.amountDownloaded.text = ""
                    }
                } else {
                    drillInCell.progressView.isHidden = true
                    drillInCell.amountDownloaded.isHidden = true
                    drillInCell.amountDownloaded.text = ""
                }
            }
            return drillInCell
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectItemEvent.onNext(indexPath)
    }

    // MARK: View
    
//    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: Private
    
    private lazy var collectionView: UICollectionView = {
        let layout = MagazineLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.register(MediaItemCell.self, forCellWithReuseIdentifier: MediaItemCell.description())
        collectionView.register(UINib(nibName: "MediaItemCell", bundle: nil), forCellWithReuseIdentifier: MediaItemCell.description())

        collectionView.isPrefetchingEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .always
        }
        return collectionView
    }()

    var itemsUpdatedAtLeastOnce = false
    
    // MARK: Dependencies
    
    internal var viewModel: MediaListingViewModel!
    internal var playbackViewModel: PlaybackControlsViewModel!

    // MARK: Fields
    
    private var viewModelSections: [MediaListingSectionViewModel] = []
    private var downloadingItems:[String: FileDownload] = [:]
    
    private var lastProgressChangedUpdate: PublishSubject<IndexPath> = PublishSubject<IndexPath>()
    private var lastDownloadCompleteUpdate: PublishSubject<IndexPath> = PublishSubject<IndexPath>()
    private let bag = DisposeBag()
    
    // MARK: Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false

        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleUserDidTapMoreNotification(notification:)), name: MediaItemCell.mediaItemCellUserDidTapMoreNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleDownloadDidInitiateNotification(notification:)), name: DownloadService.fileDownloadDidInitiateNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleDownloadDidProgressNotification(notification:)), name: DownloadService.fileDownloadDidProgressNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleDownloadDidCompleteNotification(notification:)), name: DownloadService.fileDownloadDidCompleteNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleDownloadDidCancelNotification(notification:)), name: DownloadService.fileDownloadDidCancelNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleDownloadDidErrorNotification(notification:)), name: DownloadService.fileDownloadDidErrorNotification, object: nil)

//        registerReusableViews()
//        bindToViewModel()
        reactToViewModel()
        bindPlaybackViewModel()

    }
    deinit {
        // Remove all KVO and notification observers.
        let notificationCenter = NotificationCenter.default

        notificationCenter.removeObserver(self, name: MediaItemCell.mediaItemCellUserDidTapMoreNotification, object: nil)
        
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidInitiateNotification, object: nil)
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidProgressNotification, object: nil)
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidCompleteNotification, object: nil)
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidCancelNotification, object: nil)
        notificationCenter.removeObserver(self, name: DownloadService.fileDownloadDidErrorNotification, object: nil)
    }
    
    // MARK: Private helpers
    
    private func reactToViewModel() {
        viewModel.sections.asObservable()
            .observeOn(MainScheduler.instance)
            .filter{ $0[0].items.count > 0 }
            .next { [unowned self] sections in
                // first time loading sections
                if self.itemsUpdatedAtLeastOnce == false {
                    self.viewModelSections = sections
                    self.collectionView.reloadData()
                    self.itemsUpdatedAtLeastOnce = true
                }
                else {
                    let currentItemsCount: Int = self.viewModelSections[0].items.count
                    let appendCount: Int = sections[0].items.count - currentItemsCount
                    let newItems = Array(sections[0].items.suffix(appendCount))
                    DDLogDebug("newItems.count: \(newItems.count)")
                    
                    let insertIndexPaths = Array(currentItemsCount...currentItemsCount + newItems.count-1).map { IndexPath(item: $0, section: 0) }
                    DDLogDebug("insertIndexPaths: \(insertIndexPaths)")
                    self.viewModelSections = sections
                    
                    DispatchQueue.main.async {
                        self.collectionView.performBatchUpdates({
                            self.collectionView.insertItems(at: insertIndexPaths)
                        }, completion: { result in
                            self.collectionView.reloadData()
                        })
                    }
                }
            }.disposed(by: bag)
        
        
        // refresh the collection view every quarter second
        // so we can see things like download progress happen
        lastProgressChangedUpdate
            .observeOn(MainScheduler.instance)
//            .distinctUntilChanged()
            .throttle(.milliseconds(250), scheduler: MainScheduler.instance)
            .subscribe { [unowned self] indexPath in
                //                UIView.setAnimationsEnabled(false)
                if let path: IndexPath = indexPath.element {
                    UIView.performWithoutAnimation {
                        self.collectionView.reloadItemsAtIndexPaths([path], animationStyle: .none)
                    }
                }
                //                UIView.setAnimationsEnabled(true)
            }
        .disposed(by: bag)

        // refresh the collection view when a download completes
        // this should not be throttled to ensure
        // we capture the update
        lastDownloadCompleteUpdate
            .observeOn(MainScheduler.instance)
            .subscribe { [unowned self] indexPath in
                //                UIView.setAnimationsEnabled(false)
                if let path: IndexPath = indexPath.element {
                    UIView.performWithoutAnimation {
                        self.collectionView.reloadItemsAtIndexPaths([path], animationStyle: .none)
                    }
                }
                //                UIView.setAnimationsEnabled(true)
            }
            .disposed(by: bag)

    }

    private func bindPlaybackViewModel() {
        playbackViewModel.playbackState
            .asObservable()
            .observeOn(MainScheduler.instance)
            .next { [unowned self] playbackState in
//                guard let pauseImage: UIImage = UIImage(named: "pause"),
//                    let playImage: UIImage = UIImage(named: "play"),
//                    let fullPlayImage: UIImage = UIImage(named: "nowPlaying_play"),
//                    let fullPauseImage: UIImage = UIImage(named: "nowPlaying_pause") else { return }
//
//                let accessibilityPlay: String = NSLocalizedString("Play", comment: "")
//                let accessibilityPause: String = NSLocalizedString("Pause", comment: "")
                switch playbackState {
                    
                case .initial:
                    DDLogDebug("MediaListingViewController: .initial")
//                    self.playPauseButton.image = playImage
//                    self.playPauseButton.accessibilityLabel = accessibilityPlay
//
//                    self.fullPlayPauseButton.setImage(fullPlayImage, for: .normal)
//                    self.fullPlayPauseButton.accessibilityLabel = accessibilityPlay
                case .playing:
                    DDLogDebug("MediaListingViewController: .playing")
//                    self.playPauseButton.image = pauseImage
//                    self.playPauseButton.accessibilityLabel = accessibilityPause
//
//                    self.fullPlayPauseButton.setImage(fullPauseImage, for: .normal)
//                    self.fullPlayPauseButton.accessibilityLabel = accessibilityPause
                case .paused:
                    
                    DDLogDebug("MediaListingViewController: .paused")
//                    self.playPauseButton.image = playImage
//                    self.playPauseButton.accessibilityLabel = accessibilityPlay
//
//                    self.fullPlayPauseButton.setImage(fullPlayImage, for: .normal)
//                    self.fullPlayPauseButton.accessibilityLabel = accessibilityPlay
                case .interrupted:
                    DDLogDebug("MediaListingViewController: .interrupted")
//                    self.playPauseButton.image = playImage
//                    self.playPauseButton.accessibilityLabel = accessibilityPlay
//
//                    self.fullPlayPauseButton.setImage(fullPlayImage, for: .normal)
//                    self.fullPlayPauseButton.accessibilityLabel = accessibilityPlay
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
                    let prodUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path)) else { return }
                
//                let url: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(selectedPlayable.uuid.appending(String(describing: ".\(prodUrl.pathExtension)"))).path)
//
//                var playbackPosition: Double = 0
//                var playableUuid: String = playable.uuid
//                if let historyPlayable: UserActionPlayable = playable as? UserActionPlayable {
//                    //                if let historyPlayable: UserActionPlayable = playable as? UserActionPlayable,
//                    //                    historyPlayable.mediaCategory == "preaching" {
//                    playbackPosition = historyPlayable.playbackPosition
//                    playableUuid = historyPlayable.playableUuid
//                }
//
//                var playbackRate: Float = 1.0
//                if let playbackSpeed: Float = UserDefaults.standard.object(forKey: UserPrefs.playbackSpeed.rawValue) as? Float {
//                    playbackRate = playbackSpeed
//                }
//
//                DDLogDebug("Asset playableUuid: \(playableUuid)")
//
//                self.playbackAsset = Asset(name: localizedName,
//                                           artist: presenterName,
//                                           uuid: playableUuid,
//                                           fileExtension: prodUrl.pathExtension,
//                                           playbackPosition: playbackPosition,
//                                           playbackRate: playbackRate,
//                                           urlAsset: AVURLAsset(url: FileManager.default.fileExists(atPath: url.path) ? url : prodUrl))
//
//                self.playbackViewModel.assetPlaybackService.assetPlaybackManager.pause()
//                self.playbackViewModel.assetPlaybackService.assetPlaybackManager.asset = self.playbackAsset
//                self.downloadingViewModel.downloadAsset.value = self.playbackAsset
//                // do not pass-in UserActionPlayable to historyservice or the playable.uuid and useractionplayable.playableUuid's will
//                // get mixed-up
//                self.userActionsViewModel.playable = selectedPlayable
            }
            .disposed(by: bag)

    }
//    private func reactToContentSizeChange() {
//        // Only dynamically change in iOS 11+. With iOS 10, user must re-launch app
//        if #available(iOS 11, *) {
//            NotificationCenter.default.rx
//                .notification(NSNotification.Name.UIContentSizeCategoryDidChange)
//                .next { [unowned self] _ in
//                    // With self sizing done in collectionView:cellForItemAt, the layout doesn't yet know to recalculate the layout attributes
//                    self.collectionView.collectionViewLayout.invalidateLayout()
//                }
//                .disposed(by: bag)
//        }
//    }
    
    private func registerReusableViews() {
        collectionView.register(cellType: DeviceGroupSelectionCell.self)
    }

//    private func bindToViewModel() {
//        collectionView.rx.setDelegate(self).disposed(by: bag)
//        viewModel.sections.asObservable()
//            .bind(to: collectionView.rx.items(dataSource: rxDataSource()))
//            .disposed(by: bag)
//
//        collectionView.rx.itemSelected.asObservable()
//            .subscribe(viewModel.selectItemEvent.asObserver())
//            .disposed(by: bag)
//    }
    
    // returns -1 on not found
    private func indexOfFileDownloadInViewModel(fileDownload: FileDownload) -> IndexPath {
        // try to find the indexPath of the media item and update
        // the progressevent with the indexPath so we can reload
        // a single row in the collectionView and avoid scrolling issues
        
        // assume section 0
        let items: [MediaListingItemType] = viewModelSections[0].items
        let index: Int = items.firstIndex(where: { item in
            switch item {
            case let .drillIn(enumPlayable, iconName, title, presenter, showBottomSeparator, showAmountDownloaded):
                switch enumPlayable {
                    
                case .playable(let item):
                    return item.uuid == fileDownload.playableUuid
                }
            }
            
        }) ?? -1
        return IndexPath(row: index, section: 0)
    }
    
    @objc func handleUserDidTapMoreNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        
        let actionController = YoutubeActionController()
        
//        actionController.addAction(Action(ActionData(title: "Add to Watch Later", image: UIImage(named: "yt-add-to-watch-later-icon")!), style: .default, handler: { action in
//        }))
        actionController.addAction(Action(ActionData(title: "Download...", image: UIImage(named: "cloud-gray-38px")!), style: .default, handler: { action in
        }))
        actionController.addAction(Action(ActionData(title: "Share...", image: UIImage(named: "yt-share-icon")!), style: .default, handler: { action in
        }))
        actionController.addAction(Action(ActionData(title: "Cancel", image: UIImage(named: "yt-cancel-icon")!), style: .cancel, handler: nil))
        
        present(actionController, animated: true, completion: nil)

        //        if let fileDownload: FileDownload = notification.object as? FileDownload,
        //            let downloadAsset: Asset = self.downloadAsset.value {
        //            DDLogDebug("initiateNotification filedownload: \(fileDownload)")
        //            if fileDownload.localUrl.lastPathComponent == downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")) {
        //
        //                self.downloadState.onNext(.initiating)
        //            }
        //
        //        }
    }
    
    @objc func handleDownloadDidInitiateNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            DDLogDebug("MediaListingViewController initiateNotification filedownload: \(fileDownload)")
            DDLogDebug("MediaListingViewController lastPathComponent: \(fileDownload.localUrl.lastPathComponent)")
            
            downloadingItems[fileDownload.playableUuid] = fileDownload
            
            // try to find the indexPath of the media item and update
            // the progressevent with the indexPath so we can reload
            // a single row in the collectionView and avoid scrolling issues
            
            // assume section 0
//            let items: [MediaListingItemType] = viewModelSections[0].items
//            let index: Int = items.firstIndex(where: { item in
////                $0.uuid == fileDownload.playableUuid
//
//                switch item {
//                case let .drillIn(enumPlayable, iconName, title, presenter, showBottomSeparator, showAmountDownloaded):
//                    switch enumPlayable {
//
//                    case .playable(let item):
////                        drillInCell.set(uuid: item.uuid, title: title, presenter: presenter, showBottomSeparator: showBottomSeparator, showAmountDownloaded: showAmountDownloaded)
//
//                        return item.uuid == fileDownload.playableUuid
////                        if let fileDownload: FileDownload = downloadingItems[item.uuid] {
////
////                        } else {
////                        }
//                    }
//                }
//
//            }) ?? -1

            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
            if indexPath.row != -1 {
                lastProgressChangedUpdate.onNext(indexPath)
            }
        }
    }
    
    @objc func handleDownloadDidProgressNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            DDLogDebug("MediaListingViewController didProgressNotification fileDownload: \(fileDownload.localUrl) | \(fileDownload.completedCount) / \(fileDownload.totalCount)(\(fileDownload.progress) | \(fileDownload.state))")
            DDLogDebug("MediaListingViewController lastPathComponent: \(fileDownload.localUrl.lastPathComponent)")
            
            downloadingItems[fileDownload.playableUuid] = fileDownload
            
            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
            if indexPath.row != -1 {
                lastProgressChangedUpdate.onNext(indexPath)
            }

//            lastProgressChangedUpdate.onNext(Date())
        }
    }
    
    @objc func handleDownloadDidCompleteNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            DDLogDebug("MediaListingViewController completeNotification filedownload: \(fileDownload)")
            DDLogDebug("MediaListingViewController lastPathComponent: \(fileDownload.localUrl.lastPathComponent)")
            
            downloadingItems[fileDownload.playableUuid] = fileDownload
//            lastProgressChangedUpdate.onNext(Date())
//            lastDownloadCompleteUpdate.onNext(Date())
            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
            if indexPath.row != -1 {
                lastDownloadCompleteUpdate.onNext(indexPath)
            }

        }
    }
    
    @objc func handleDownloadDidErrorNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            DDLogDebug("MediaListingViewController errorNotification filedownload: \(fileDownload)")
            DDLogDebug("MediaListingViewController lastPathComponent: \(fileDownload.localUrl.lastPathComponent)")
            
            downloadingItems[fileDownload.playableUuid] = fileDownload
            
//            lastProgressChangedUpdate.onNext(Date())
            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
            if indexPath.row != -1 {
                lastProgressChangedUpdate.onNext(indexPath)
            }

        }
    }
    
    @objc func handleDownloadDidCancelNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            DDLogDebug("MediaListingViewController cancelNotification filedownload: \(fileDownload)")
            DDLogDebug("MediaListingViewController lastPathComponent: \(fileDownload.localUrl.lastPathComponent)")
            
            downloadingItems[fileDownload.playableUuid] = fileDownload
            
//            lastProgressChangedUpdate.onNext(Date())
            let indexPath: IndexPath = indexOfFileDownloadInViewModel(fileDownload: fileDownload)
            if indexPath.row != -1 {
                lastProgressChangedUpdate.onNext(indexPath)
            }

        }
    }
}

extension MediaListingViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //        DDLogDebug("scrollViewDidEndDecelerating scrollView: \(scrollView)")
        
        let offsetDiff: CGFloat = scrollView.contentSize.height - scrollView.contentOffset.y
        //        DDLogDebug("offset diff: \(offsetDiff)")
        DDLogDebug("near bottom: \(offsetDiff - collectionView.frame.size.height)")
        //        if scrollView.contentSize.height - scrollView.contentOffset.y <
        
        if offsetDiff - collectionView.frame.size.height <= 20.0 {
            DDLogDebug("fetch!")
            viewModel.fetchMoreMedia()
        }
    }
}


// MARK: UICollectionViewDelegateMagazineLayout

extension MediaListingViewController: UICollectionViewDelegateMagazineLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeModeForItemAt indexPath: IndexPath) -> MagazineLayoutItemSizeMode {
        return MagazineLayoutItemSizeMode(widthMode: .fullWidth(respectsHorizontalInsets: true), heightMode: .dynamic)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForHeaderInSectionAtIndex index: Int) -> MagazineLayoutHeaderVisibilityMode {
        return MagazineLayout.Default.HeaderVisibilityMode
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForFooterInSectionAtIndex index: Int) -> MagazineLayoutFooterVisibilityMode {
        return MagazineLayout.Default.FooterVisibilityMode
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, visibilityModeForBackgroundInSectionAtIndex index: Int) -> MagazineLayoutBackgroundVisibilityMode {
        return MagazineLayout.Default.BackgroundVisibilityMode
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, horizontalSpacingForItemsInSectionAtIndex index: Int) -> CGFloat {
        return 12
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, verticalSpacingForElementsInSectionAtIndex index: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 4, bottom: 24, right: 4)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForItemsInSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 4, bottom: 24, right: 4)
    }
}

