import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import XLActionController
import MagazineLayout

/// Add service screen
public final class MediaListingViewController: UIViewController, UICollectionViewDataSource /*,  UICollectionViewDelegate */ {
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
//    internal var searchViewModel: MediaSearchViewModel!
    internal var playbackViewModel: PlaybackControlsViewModel!
    internal var downloadListingViewModel: DownloadListingViewModel!
    internal var mediaSearchResultsViewController: MediaSearchResultsViewController!

    // MARK: Fields
    
    internal var viewModelSections: [MediaListingSectionViewModel] = []
    internal var downloadingItems: [String: FileDownload] = [:]
    internal var downloadedItems: [String: FileDownload] = [:]
    internal var selectedPlayable: Field<Playable?> = Field<Playable?>(nil)
    internal var previousSelectedPlayable: Field<Playable?> = Field<Playable?>(nil)
    internal var playbackState = Field<AssetPlaybackManager.playbackState>(.initial)
    
    /// MARK: Search

    internal var viewModelSearchSections: [MediaListingSectionViewModel] = []
    var products = [Product]() // for testing of search only, remove once navigation is working

    /// State restoration values.
    private enum RestorationKeys: String {
        case viewControllerTitle
        case searchControllerIsActive
        case searchBarText
        case searchBarIsFirstResponder
    }
    
    private struct SearchControllerRestorableState {
        var wasActive = false
        var wasFirstResponder = false
    }
    
    private var searchController: UISearchController = UISearchController(searchResultsController: nil)
    /// Secondary search results table view.
//    internal var resultsTableController: ResultsTableController!
//    internal var mediaSearchResultsViewController: MediaSearchResultsViewController!
    /// Restoration state for UISearchController
    private var restoredState = SearchControllerRestorableState()

    /// UISearchBar
    private var filterText: String? = nil

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
        
        // MediaItemCell
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleUserDidTapMoreNotification(notification:)), name: MediaItemCell.mediaItemCellUserDidTapMoreNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleUserDidTapCancelNotification(notification:)), name: MediaItemCell.mediaItemCellUserDidTapCancelNotification, object: nil)
        
        // DownloadService
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleDownloadDidInitiateNotification(notification:)), name: DownloadService.fileDownloadDidInitiateNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleDownloadDidProgressNotification(notification:)), name: DownloadService.fileDownloadDidProgressNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleDownloadDidCompleteNotification(notification:)), name: DownloadService.fileDownloadDidCompleteNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleDownloadDidCancelNotification(notification:)), name: DownloadService.fileDownloadDidCancelNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(MediaListingViewController.handleDownloadDidErrorNotification(notification:)), name: DownloadService.fileDownloadDidErrorNotification, object: nil)
        
        /// SEARCH
        
//        resultsTableController = ResultsTableController()
        
//        let dependencyModule = AppDependencyModule()
//
//        let uiFactory = dependencyModule.resolver.resolve(UIFactory.self)!
//        let mediaSearchResultsViewController: MediaSearchResultsViewController = uiFactory.makeMediaSearching(playlistId: viewModel.playlistUuid, mediaCategory: viewModel.mediaCategory)

        
        
//        resultsTableController.tableView.delegate = self
//        searchController = UISearchController(searchResultsController: resultsTableController)
        
        searchController = UISearchController(searchResultsController: mediaSearchResultsViewController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self // Monitor when the search button is tapped.
        searchController.searchBar.autocapitalizationType = .none
        //        searchController.dimsBackgroundDuringPresentation = true // The default is true.
        searchController.delegate = self
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // have view model capture uisearchbar keyboard events
        // for filter use case
//        searchController.searchBar.rx.text
//            .orEmpty
//            .distinctUntilChanged()
//            .debug()
//            .bind(to: viewModel.filterText)
//            .disposed(by: bag)
        
        // capture back the filterText to view controller
        // (may not need this)
//        viewModel.filterText
//            .observeOn(MainScheduler.instance)
//            .subscribe { [unowned self] filterText in
//                DDLogDebug("filterText: \(filterText)")
//                if let text: String = filterText.element {
//                    self.filterText = text
//                }
//            }
//            .disposed(by: bag)
        
        // capture search button tap event
        searchController.searchBar.rx
            .searchButtonClicked
            .debug()
            .subscribe(onNext: { [unowned self] _ in
                if let searchText: String = self.searchController.searchBar.text {
//                    self.viewModel.searchText.value = searchText
                    self.mediaSearchResultsViewController.viewModel.searchText.value = searchText
                }
            })
            .disposed(by: bag)
        
        // observe changes on the searchedSections and refresh
        // search results if there are
//        viewModel.searchedSections
//            .asObservable()
//            .observeOn(MainScheduler.instance)
//            .next { [unowned self] sections in
//                self.viewModelSearchSections = sections
//                self.resultsTableController.viewModelSearchSections = sections
//                self.resultsTableController.tableView.reloadData()
//            }.disposed(by: bag)

//        mediaSearchResultsViewController.viewModel.sections
//            .asObservable()
//            .observeOn(MainScheduler.instance)
//            .next { [unowned self] sections in
////                self.viewModelSearchSections = sections
//                self.mediaSearchResultsViewController.viewModelSections = sections
////                self.mediaSearchResultsViewController.collectionView.reloadData()
//            }.disposed(by: bag)

        
        reactToViewModel()
        bindPlaybackViewModel()
        bindDownloadListingViewModel()
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        // https://stackoverflow.com/a/49033096
        
        /** Search presents a view controller by applying normal view controller presentation semantics.
         This means that the presentation moves up the view controller hierarchy until it finds the root
         view controller or one that defines a presentation context.
         */
        
        /** Specify that this view controller determines how the search controller is presented.
         The search controller should be presented modally and match the physical size of this view controller.
         */
        definesPresentationContext = true

    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Restore the searchController's active state.
        if restoredState.wasActive {
            searchController.isActive = restoredState.wasActive
            restoredState.wasActive = false
            
            if restoredState.wasFirstResponder {
                searchController.searchBar.becomeFirstResponder()
                restoredState.wasFirstResponder = false
            }
        }
    }

    
    deinit {
        // Remove all KVO and notification observers.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.removeObserver(self, name: MediaItemCell.mediaItemCellUserDidTapMoreNotification, object: nil)
        notificationCenter.removeObserver(self, name: MediaItemCell.mediaItemCellUserDidTapCancelNotification, object: nil)
        
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
                self.playbackState.value = playbackState
                
                if let previousSelectedPlayable: Playable = self.previousSelectedPlayable.value,
                    let indexPath: IndexPath = self.indexOfPlayableInViewModel(playable: previousSelectedPlayable) {
                    if indexPath.row >= 0 {
                        UIView.performWithoutAnimation {
                            self.collectionView.reloadItemsAtIndexPaths([indexPath], animationStyle: .none)
                        }
                    }
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
                guard let selectedPlayable: Playable = self.playbackViewModel.selectedPlayable.value else { return }
                
                self.previousSelectedPlayable.value = self.selectedPlayable.value
                self.selectedPlayable.value = selectedPlayable
                
                if let selected: Playable = self.selectedPlayable.value,
                    let indexPath: IndexPath = self.indexOfPlayableInViewModel(playable: selected) {
                    if indexPath.row >= 0 {
                        UIView.performWithoutAnimation {
                            self.collectionView.reloadItemsAtIndexPaths([indexPath], animationStyle: .none)
                        }
                    }
                }
            }
            .disposed(by: bag)
        
    }
    
    private func bindDownloadListingViewModel() {
        
        // the moment the viewmodel playlistuuid changes we
        // get the file downloads for that playlist
        downloadListingViewModel.storedFileDownloads(for: viewModel.playlistUuid)
            .asObservable()
            .subscribe(onNext: { fileDownloads in
                
                fileDownloads.forEach({ [unowned self] fileDownload in
                    self.downloadedItems[fileDownload.playableUuid] = fileDownload
                })
                
                DDLogDebug("viewModel.playlistUuid: \(self.viewModel.playlistUuid) fileDownloads: \(fileDownloads)")
            })
            .disposed(by: bag)
        
        // refresh the collection view when a download gets deleted
        // this should not be throttled to ensure
        // we capture the update
        downloadListingViewModel.fileDownloadDeleted
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe { [unowned self] playableUuid in
                
                if let playableUuid: String? = playableUuid.element,
                    let uuid: String = playableUuid,
                    let download: FileDownload = self.downloadedItems[uuid],
                    let indexPath: IndexPath = self.indexOfFileDownloadInViewModel(fileDownload: download) {
                    
                    // remove it from downloadedItems
                    self.downloadedItems[uuid] = nil
                    
                    if indexPath.row >= 0 {
                        UIView.performWithoutAnimation {
                            self.collectionView.reloadItemsAtIndexPaths([indexPath], animationStyle: .none)
                        }
                    }
                }
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
        
    // returns -1 on not found
    private func indexOfFileDownloadInViewModel(fileDownload: FileDownload) -> IndexPath {
        // try to find the indexPath of the media item and update
        // the progressevent with the indexPath so we can reload
        // a single row in the collectionView and avoid scrolling issues
        
        var index: Int = -1
        var indexPath: IndexPath = IndexPath(row: index, section: 0)
        
        // assume section 0
        
        if viewModelSections.count > 0 {
            let items: [MediaListingItemType] = viewModelSections[0].items
            if items.count > 0 {
                index = items.firstIndex(where: { item in
                    switch item {
                    case let .drillIn(enumPlayable, _, _, _, _):
                        switch enumPlayable {
                            
                        case .playable(let item):
                            return item.uuid == fileDownload.playableUuid
                        }
                    }
                    
                }) ?? -1
            }
        }
        
        indexPath = IndexPath(row: index, section: 0)
        return indexPath
    }

    // returns -1 on not found
    private func indexOfPlayableInViewModel(playable: Playable) -> IndexPath {
        // try to find the indexPath of the media item and update
        // the progressevent with the indexPath so we can reload
        // a single row in the collectionView and avoid scrolling issues
        
        var index: Int = -1
        var indexPath: IndexPath = IndexPath(row: index, section: 0)
        
        // assume section 0
        
        if viewModelSections.count > 0 {
            let items: [MediaListingItemType] = viewModelSections[0].items
            if items.count > 0 {
                index = items.firstIndex(where: { item in
                    switch item {
                    case let .drillIn(enumPlayable, _, _, _, _):
                        switch enumPlayable {
                            
                        case .playable(let item):
                            return item.uuid == playable.uuid
                        }
                    }
                    
                }) ?? -1
            }
        }
        indexPath = IndexPath(row: index, section: 0)
        return indexPath
    }

    // MARK: MediaItemCell notifications
    
    @objc func handleUserDidTapMoreNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        /*
         - some : Faithful_Word.MediaItem(contentProviderLink: nil, duration: 0.0, hashId: "gqRj", insertedAt: 1565925286.0, ipfsLink: nil, languageId: "en", largeThumbnailPath: nil, localizedname: "Matthew 1", medThumbnailPath: nil, mediaCategory: "bible", medium: "audio", ordinal: Optional(1), path: Optional("bible/en/0040-0001-Matthew-en.mp3"), playlistUuid: "8e06e658-9cdf-4ca0-8aa5-a3e958e6b035", presentedAt: nil, presenterName: Optional("Eli Lambert"), publishedAt: nil, smallThumbnailPath: nil, sourceMaterial: Optional("King James Bible (KJV)"), tags: [], trackNumber: Optional(1), updatedAt: Optional(1565925318.0), uuid: "39be7a9d-fbe8-49a3-a5d4-16c3e10b0c2d")
         */
        if let mediaItem: MediaItem = notification.object as? MediaItem,
            let path: String = mediaItem.path,
            let remoteUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path)) {
            let actionController = YoutubeActionController()
            
            
            let fileIdentifier: String = mediaItem.uuid.appending(String(describing: ".\(remoteUrl.pathExtension)"))
            //        actionController.addAction(Action(ActionData(title: "Add to Watch Later", image: UIImage(named: "yt-add-to-watch-later-icon")!), style: .default, handler: { action in
            //        }))
            
            if let fileDownload: FileDownload = downloadedItems[mediaItem.uuid] {
                actionController.addAction(Action(ActionData(title: "Delete File...", image: UIImage(named: "cloud-gray-38px")!), style: .default, handler: { action in
                    self.downloadListingViewModel.deleteFileDownload(for: mediaItem.uuid, pathExtension: remoteUrl.pathExtension)
                }))
            } else if let downloading: FileDownload = downloadingItems[mediaItem.uuid] {
                actionController.addAction(Action(ActionData(title: "Cancel Download...", image: UIImage(named: "cloud-gray-38px")!), style: .default, handler: { action in
                    self.downloadListingViewModel.cancelDownload(for: mediaItem, playlistUuid: mediaItem.playlistUuid)
                }))
            }
            else {
                actionController.addAction(Action(ActionData(title: "Download...", image: UIImage(named: "cloud-gray-38px")!), style: .default, handler: { action in
                    //                self.downloadListingService. fetchDownload(url: remoteUrl.absoluteString, filename: fileIdentifier, playableUuid: mediaItem.uuid)
                    self.downloadListingViewModel.fetchDownload(for: mediaItem, playlistUuid: mediaItem.playlistUuid)
                    
                }))
            }
            if let fileDownload: FileDownload = downloadedItems[mediaItem.uuid] {
                actionController.addAction(Action(ActionData(title: "Share File...", image: UIImage(named: "yt-share-icon")!), style: .default, handler: { action in
                    
                    self.shareFile(mediaItem: mediaItem)
                }))
            }
            actionController.addAction(Action(ActionData(title: "Share Link...", image: UIImage(named: "yt-share-icon")!), style: .default, handler: { action in
                self.shareLink(mediaItem: mediaItem)
            }))

            actionController.addAction(Action(ActionData(title: "Cancel", image: UIImage(named: "yt-cancel-icon")!), style: .cancel, handler: nil))
            
            present(actionController, animated: true, completion: nil)
        }
        
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
    
    //    handleUserDidTapCancelNotification
    
    @objc func handleUserDidTapCancelNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
        if let mediaItem: MediaItem = notification.object as? MediaItem {
            self.downloadListingViewModel.cancelDownload(for: mediaItem, playlistUuid: mediaItem.playlistUuid)
        }
        
        
    }
    // MARK: DownloadService notifications
    
    @objc func handleDownloadDidInitiateNotification(notification: Notification) {
        if let fileDownload: FileDownload = notification.object as? FileDownload {
            DDLogDebug("MediaListingViewController initiateNotification filedownload: \(fileDownload)")
            DDLogDebug("MediaListingViewController lastPathComponent: \(fileDownload.localUrl.lastPathComponent)")
            
            downloadingItems[fileDownload.playableUuid] = fileDownload
            
            self.downloadListingViewModel.updateFileDownloadHistory(for: fileDownload)
            
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
            
            self.downloadListingViewModel.updateFileDownloadHistory(for: fileDownload)
            
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
            
            // store download as `downloaded`
            downloadedItems[fileDownload.playableUuid] = fileDownload
            
            self.downloadListingViewModel.updateFileDownloadHistory(for: fileDownload)
            
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
            
            self.downloadListingViewModel.updateFileDownloadHistory(for: fileDownload)
            
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
            
            self.downloadListingViewModel.updateFileDownloadHistory(for: fileDownload)
            
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
        
        if collectionView == scrollView {
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

// https://stackoverflow.com/a/49343299
extension MediaListingViewController {
    func fileSizeFormattedString(for fileSize: Int64) -> String {
        // bytes
        if fileSize < 1023 {
            return String(format: "%lu bytes", CUnsignedLong(fileSize))
        }
        // KB
        var floatSize = Float(fileSize / 1024)
        if floatSize < 1023 {
            return String(format: "%.1f KB", floatSize)
        }
        // MB
        floatSize = floatSize / 1024
        if floatSize < 1023 {
            return String(format: "%.1f MB", floatSize)
        }
        // GB
        floatSize = floatSize / 1024
        return String(format: "%.1f GB", floatSize)
    }
}

extension MediaListingViewController {
    func shareLink(mediaItem: MediaItem) {
        if let hashLink: URL = URL(string: "https://api.faithfulword.app/m"),
            let presenterName: String = mediaItem.presenterName ?? "Unknown Presenter",
            let shareUrl: URL = hashLink.appendingPathComponent(mediaItem.hashId) {
            DDLogDebug("hashLink: \(shareUrl)")
            
            let message = MessageWithSubjectActivityItem(subject: String(describing: "\(mediaItem.localizedname) by \(presenterName)"), message: "Shared via the Faithful Word App: https://faithfulwordapp.com/")
            let itemsToShare: [Any] = [message, shareUrl]
            
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
        

    }
    
    func shareFile(mediaItem: MediaItem) {
        // copy file to temp dir to rename it
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        // generate temp file url path
        
        if let presenterName: String = mediaItem.presenterName ?? "Unknown Presenter",
            let path: String = mediaItem.path,
            let remoteUrl: URL = URL(string: EnvironmentUrlItemKey.ProductionFileStorageRootUrl.rawValue.appending("/").appending(path)) {
            
            let firstPart: String = "\(presenterName.replacingOccurrences(of: " ", with: ""))"
            let secondPart: String = "\(mediaItem.localizedname.replacingOccurrences(of: " ", with: "")).\(remoteUrl.pathExtension)"
            let destinationLastPathComponent: String = String(describing: "\(firstPart)-\(secondPart)")
            
            let sourceFileUrl: URL = FileSystem.savedDirectory.appendingPathComponent(mediaItem.uuid.appending(String(describing: ".\(remoteUrl.pathExtension)")))
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
            
            let message = MessageWithSubjectActivityItem(subject: String(describing: "\(mediaItem.localizedname) by \(presenterName)"), message: "Shared via the Faithful Word App: https://faithfulwordapp.com/")
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
        

    }
}

// MARK: UISearchControllerDelegate

extension MediaListingViewController: UISearchControllerDelegate {
    public func willPresentSearchController(_ searchController: UISearchController) {
        DDLogDebug("searchController: \(String(describing: searchController))")
    }

    public func didPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            searchController.searchBar.becomeFirstResponder()
        }
    }
}

// MARK: UISearchBarDelegate

extension MediaListingViewController: UISearchBarDelegate {
    
    public override func resignFirstResponder() -> Bool {
        return true
    }
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        DDLogDebug("searchBar: \(String(describing: searchBar.text))")
        searchBar.resignFirstResponder()
    }
    
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        
        return true
    }
    
    public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        
        searchBar.setShowsCancelButton(false, animated: true)
        return true
//        var textHasChars: Bool = false
//
//        if let filterText: String = self.filterText {
//            textHasChars = (filterText.count) > 0
//        }
//        return !textHasChars
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            DDLogDebug("probably cleared searchbar")
            mediaSearchResultsViewController.viewModel.cancelSearch.value = searchText
        }
    }
}

extension MediaListingViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        DDLogDebug("searchController: \(String(describing: searchController))")
    }
}

// MARK: - UIStateRestoration

extension MediaListingViewController {
    override public func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        // Encode the view state so it can be restored later.
        
        // Encode the title.
        coder.encode(navigationItem.title!, forKey: RestorationKeys.viewControllerTitle.rawValue)
        
        // Encode the search controller's active state.
        coder.encode(searchController.isActive, forKey: RestorationKeys.searchControllerIsActive.rawValue)
        
        // Encode the first responser status.
        coder.encode(searchController.searchBar.isFirstResponder, forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)
        
        // Encode the search bar text.
        coder.encode(searchController.searchBar.text, forKey: RestorationKeys.searchBarText.rawValue)
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        // Restore the title.
        guard let decodedTitle = coder.decodeObject(forKey: RestorationKeys.viewControllerTitle.rawValue) as? String else {
            fatalError("A title did not exist. In your app, handle this gracefully.")
        }
        navigationItem.title! = decodedTitle
        
        /** Restore the active state:
         We can't make the searchController active here since it's not part of the view
         hierarchy yet, instead we do it in viewWillAppear.
         */
        restoredState.wasActive = coder.decodeBool(forKey: RestorationKeys.searchControllerIsActive.rawValue)
        
        /** Restore the first responder status:
         Like above, we can't make the searchController first responder here since it's not part of the view
         hierarchy yet, instead we do it in viewWillAppear.
         */
        restoredState.wasFirstResponder = coder.decodeBool(forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)
        
        // Restore the text in the search field.
        searchController.searchBar.text = coder.decodeObject(forKey: RestorationKeys.searchBarText.rawValue) as? String
    }
    
}
