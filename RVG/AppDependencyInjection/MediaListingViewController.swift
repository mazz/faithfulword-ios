import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import MagazineLayout

/// Add service screen
public final class MediaListingViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return viewModelSections[0].items.count // MediaListingItemType
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        
//        if viewModelSections[0].items.count > 0 {
        DDLogDebug("viewModelSections[0].items[indexPath.row]: \(viewModelSections[0].items[indexPath.row])")
//        }
        let item: MediaListingItemType = viewModelSections[0].items[indexPath.row]
    
        switch item {
        case let .drillIn(_, iconName, title, presenter, showBottomSeparator):
            let drillInCell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaItemCell.description(), for: indexPath) as! MediaItemCell
            drillInCell.set(title: title, presenter: presenter)
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

//        collectionView.register(
//            Header.self,
//            forSupplementaryViewOfKind: MagazineLayout.SupplementaryViewKind.sectionHeader,
//            withReuseIdentifier: Header.description())
//        collectionView.register(
//            Footer.self,
//            forSupplementaryViewOfKind: MagazineLayout.SupplementaryViewKind.sectionFooter,
//            withReuseIdentifier: Footer.description())
//        collectionView.register(
//            Background.self,
//            forSupplementaryViewOfKind: MagazineLayout.SupplementaryViewKind.sectionBackground,
//            withReuseIdentifier: Background.description())
        collectionView.isPrefetchingEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .always
        }
        return collectionView
    }()

    
    // MARK: Dependencies
    
    internal var viewModel: MediaListingViewModel!
    
    // MARK: Fields
    
    private var viewModelSections: [MediaListingSectionViewModel] = []
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
//        registerReusableViews()
//        bindToViewModel()
        reactToViewModel()

    }
    
    // MARK: Private helpers
    
    private func reactToViewModel() {
        viewModel.sections.asObservable()
            .next { [unowned self] sections in
                // Cache our viewModel sections, so we don't need to read the value while it' still being written to
                self.viewModelSections = sections
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
            }.disposed(by: bag)
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

    private func bindToViewModel() {
        collectionView.rx.setDelegate(self).disposed(by: bag)
        viewModel.sections.asObservable()
            .bind(to: collectionView.rx.items(dataSource: rxDataSource()))
            .disposed(by: bag)

        collectionView.rx.itemSelected.asObservable()
            .subscribe(viewModel.selectItemEvent.asObserver())
            .disposed(by: bag)
    }
    
    private func rxDataSource() -> RxCollectionViewSectionedReloadDataSource<MediaListingSectionViewModel> {
        let dataSource = RxCollectionViewSectionedReloadDataSource<MediaListingSectionViewModel>(
            configureCell: { (dataSource, collectionView, indexPath, item) in
                switch item {
                case let .drillIn(_, iconName, title, presenter, showBottomSeparator):
                    let drillInCell = collectionView.dequeue(cellType: DeviceGroupSelectionCell.self, for: indexPath)
                    drillInCell.populate(iconName: iconName, label: title, showBottomSeparator: showBottomSeparator, showChevron: false)
                    return drillInCell

                }},
            configureSupplementaryView: { _, collectionView, kind, indexPath in
                return collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: UICollectionReusableView.identifierName,
                    for: indexPath)
        })
        return dataSource
    }
}

//extension MediaListingViewController: UICollectionViewDelegateFlowLayout {
//    public func collectionView(_ collectionView: UICollectionView,
//                               layout collectionViewLayout: UICollectionViewLayout,
//                               sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let preferredWidth: CGFloat = collectionView.bounds.width
//
//
//        switch viewModel.item(at: indexPath) {
//        case let .drillIn(_, iconName, title, showBottomSeparator):
//            guard let view = try? UIView.sizingView(for: DeviceGroupSelectionCell.self,
//                                                    bundle: ModuleInfo.bundle) else { break }
//            view.populate(iconName: iconName, label: title, showBottomSeparator: showBottomSeparator)
//            return CGSize(width: preferredWidth, height: view.height(for: preferredWidth))
//        }
//        return CGSize(width: 0.1, height: 0.1)
//    }
//}

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
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //        DDLogDebug("scrollViewDidEndDragging scrollView: \(scrollView)")
        
        let offsetDiff: CGFloat = scrollView.contentSize.height - scrollView.contentOffset.y
        //        DDLogDebug("offset diff: \(offsetDiff)")
        DDLogDebug("near bottom: \(offsetDiff - collectionView.frame.size.height)")
        
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
        return 12
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 4, bottom: 24, right: 4)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForItemsInSectionAtIndex index: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 4, bottom: 24, right: 4)
    }
}

