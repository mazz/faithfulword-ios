import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import MagazineLayout
import GRDB

public final class ChannelViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewModelSections.count == 0 {
            return 0
        }
        return viewModelSections[section].items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //        DDLogDebug("viewModelSections[0].items[indexPath.row]: \(viewModelSections[indexPath.section].items[indexPath.row])")
        //        }
        let item: PlaylistItemType = viewModelSections[indexPath.section].items[indexPath.row]
        
        switch item {
        case let .drillIn(_, iconName, title, showBottomSeparator):
            let drillInCell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaylistCollectionViewCell.description(), for: indexPath) as! PlaylistCollectionViewCell
            drillInCell.populate(iconName: iconName, label: title, showBottomSeparator: showBottomSeparator, showChevron: true)
            return drillInCell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectItemEvent.onNext(indexPath)
    }
    // MARK: View
    
    private lazy var collectionView: UICollectionView = {
        let layout = MagazineLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(UINib(nibName: "PlaylistCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: PlaylistCollectionViewCell.description())
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
    
    internal var viewModel: PlaylistViewModel!
    
    // MARK: Fields
    let noResultLabel: UILabel = UILabel(frame: .zero)
    
    private var viewModelSections: [PlaylistSectionViewModel] = []
    private let bag = DisposeBag()
    
    private var observer: TransactionObserver?
    
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
        
        noResultLabel.text = NSLocalizedString("No Result Found", comment: "").l10n()
        noResultLabel.textAlignment = .center
        noResultLabel.font = UIFont.systemFont(ofSize: 32)
        noResultLabel.textColor = .gray
        noResultLabel.backgroundColor = .clear
        
        
        collectionView.addSubview(noResultLabel)
        noResultLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noResultLabel.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            noResultLabel.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            noResultLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor, constant: -100),
            noResultLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            noResultLabel.heightAnchor.constraint(equalToConstant: 300),
        ])
        
        reactToViewModel()
    }
    
    // MARK: Private helpers
    
    //        private func reactToContentSizeChange() {
    //            // Only dynamically change in iOS 11+. With iOS 10, user must re-launch app
    //            if #available(iOS 11, *) {
    //                NotificationCenter.default.rx
    //                    .notification(Notification.Name.UIContentSizeCategory.didChangeNotification)
    //                    .next { [unowned self] _ in
    //                        // With self sizing done in collectionView:cellForItemAt, the layout doesn't yet know to recalculate the layout attributes
    //                        self.collectionView.collectionViewLayout.invalidateLayout()
    //                    }
    //                    .disposed(by: bag)
    //            }
    //        }
    
    private func reactToViewModel() {
        
        //                let request = Playlist
        ////                    .filter(Column("orgUuid") == viewModel.orgUuid.value)
        //                    .filter(Column("archived") == false)
        //                    .order(Column("updatedAt").desc)
        //
        //                let coursesObservation = ValueObservation.tracking { db in
        //                    try request.fetchAll(db)
        //                }
        //
        //                //        do {
        //                observer = coursesObservation.start(in: dbPool, onError: { error in
        //                    print("CourseListController courses could not be fetched: \(error)")
        //                }, onChange: { [weak self] (mbyCourses: [Playlist]) in
        //                    print("CourseListController courses fetched: \(mbyCourses)")
        //                    self?.viewModel.courses.value = mbyCourses
        //        //            if let strongSelf = self {
        //        //                strongSelf.sections.value = strongSelf.coursesRefresh(refreshedCourses: mbyCourses)
        //        //            }
        //                })
        //
        viewModel.sections.asObservable()
            .observeOn(MainScheduler.instance)
            //            .filter{ $0[0].items.count > 0 }
            .next { [unowned self] sections in
                // first time loading sections
                if self.itemsUpdatedAtLeastOnce == false {
                    self.viewModelSections = sections
                    self.collectionView.reloadData()
                    self.itemsUpdatedAtLeastOnce = true
                }
                else {
                    // if sections are empty, that means the viewmodels sections were
                    // deleted(probably because the language was changed)
                    // in this case just hard reloadData() similar to when
                    // medialistingviewcontroller is filtering
                    
                    if sections.count == 0 || self.viewModelSections.count == 0 {
                        DispatchQueue.main.async {
                            self.viewModelSections = sections
                            self.collectionView.reloadData()
                        }
                    } else {
                        let currentItemsCount: Int = self.viewModelSections[0].items.count
                        let appendCount: Int = sections[0].items.count - currentItemsCount
                        
                        if appendCount > 0 {
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
                        } else if appendCount < 0 { // deleting items
                            let currentItemsCount: Int = self.viewModelSections[0].items.count
                            var deleteCount: Int = abs(appendCount)
                            
                            let newArray = Array(sections[0].items.dropLast(deleteCount))
                            
                            DDLogDebug("newArray.count: \(newArray.count)")
                            
                            let deleteIndexPaths = Array(currentItemsCount - deleteCount ... (currentItemsCount-1)).map { IndexPath(item: $0, section: 0) }
                            DDLogDebug("deleteIndexPaths: \(deleteIndexPaths)")
                            self.viewModelSections[0].items = newArray
                            
                            DispatchQueue.main.async {
                                self.collectionView.performBatchUpdates({
                                    self.collectionView.deleteItems(at: deleteIndexPaths)
                                }, completion: // nil
                                    { result in
                                        self.collectionView.reloadData()
                                }
                                )
                            }
                        }
                    }
                }
        }.disposed(by: bag)
        
        viewModel.emptyFetchResult.asObservable()
            .observeOn(MainScheduler.instance)
            .next { [unowned self] emptyResult in
                self.noResultLabel.isHidden = !emptyResult
                //                self.noResultLabel.isHidden = false
        }.disposed(by: bag)
        
        viewModel.fetchingPlaylists.asObservable()
            .observeOn(MainScheduler.instance)
            .next { [unowned self] fetchingResult in
                DispatchQueue.main.async {
                    self.noResultLabel.text = NSLocalizedString("Loading ...", comment: "").l10n()
                    self.noResultLabel.isHidden = !fetchingResult
                    self.collectionView.isHidden = fetchingResult
                }
        }.disposed(by: bag)
        
        
    }
}

extension ChannelViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let preferredWidth: CGFloat = collectionView.bounds.width
        
        
        switch viewModel.item(at: indexPath) {
        case let .drillIn(_, iconName, title, showBottomSeparator):
            guard let view = try? UIView.sizingView(for: PlaylistCollectionViewCell.self,
                                                    bundle: ModuleInfo.bundle) else { break }
            view.populate(iconName: iconName, label: title, showBottomSeparator: showBottomSeparator)
            return CGSize(width: preferredWidth, height: view.height(for: preferredWidth))
        }
        return CGSize(width: 0.1, height: 0.1)
    }
}

extension ChannelViewController {
    public func plant(_ viewController: UIViewController, withAnimation animation: AppAnimations.Animatable? = nil) {
        if let residualPresentedViewController = children.first?.presentedViewController {
            residualPresentedViewController.dismiss(animated: true, completion: nil)
        }
        replace(children.first, with: viewController, in: view, withAnimation: animation)
    }
}

extension ChannelViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let offsetDiff: CGFloat = scrollView.contentSize.height - scrollView.contentOffset.y
        DDLogDebug("near bottom: \(offsetDiff - collectionView.frame.size.height)")
        
        if offsetDiff - collectionView.frame.size.height <= 20.0 {
            DDLogDebug("fetch!")
            viewModel.fetchAppendPlaylists.onNext(true)
        }
    }
    
    //    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    //
    //        let offsetDiff: CGFloat = scrollView.contentSize.height - scrollView.contentOffset.y
    //        DDLogDebug("near bottom: \(offsetDiff - collectionView.frame.size.height)")
    //
    //        if offsetDiff - collectionView.frame.size.height <= 20.0 {
    //            DDLogDebug("fetch!")
    //            viewModel.fetchAppendPlaylists.onNext(true)
    //        }
    //    }
}


// MARK: UICollectionViewDelegateMagazineLayout

extension ChannelViewController: UICollectionViewDelegateMagazineLayout {
    
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

