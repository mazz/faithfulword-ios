import UIKit
import RxSwift
import RxCocoa
import RxDataSources

/// Add service screen
public final class MainViewController: UIViewController {
    // MARK: View
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: Dependencies
    
    internal var viewModel: MainViewModel!
    
    // MARK: Fields
    private var viewModelSections: [BooksSectionViewModel] = []
    private let bag = DisposeBag()
    
    // MARK: Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(cellType: DeviceGroupSelectionCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize

//        registerReusableViews()
//        bindToViewModel()
        reactToViewModel()
        reactToContentSizeChange()

    }
    
    // MARK: Private helpers
    
    private func reactToViewModel() {
        viewModel.sections.asObservable()
            .next { [unowned self] sections in
                // Cache our viewModel sections, so we don't need to read the value while it' still being written to
                self.viewModelSections = sections
                
                self.collectionView.reloadData()
            }.disposed(by: bag)
    }

    private func reactToContentSizeChange() {
        // Only dynamically change in iOS 11+. With iOS 10, user must re-launch app
        if #available(iOS 11, *) {
            NotificationCenter.default.rx
                .notification(NSNotification.Name.UIContentSizeCategoryDidChange)
                .next { [unowned self] _ in
                    // With self sizing done in collectionView:cellForItemAt, the layout doesn't yet know to recalculate the layout attributes
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
                .disposed(by: bag)
        }
    }

    
    private func registerReusableViews() {
//        collectionView.register(headerViewType: AddMusicServiceHeaderView.self, in: Bundle.main)
        collectionView.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
            withReuseIdentifier: UICollectionReusableView.identifierName)
//        collectionView.register(cellType: AddMusicServiceCell.self, in: Bundle.main)
        collectionView.register(cellType: SettingDrillInCell.self, in: Bundle.main)

    }
    
//    private func bindToViewModel() {
//        collectionView.rx.setDelegate(self).disposed(by: bag)
//        viewModel.sections.asObservable()
//            .bind(to: collectionView.rx.items(dataSource: rxDataSource()))
//            .disposed(by: bag)
//        collectionView.rx.itemSelected.asObservable()
//            .subscribe(viewModel.selectItemEvent.asObserver())
//            .disposed(by: bag)
////        viewModel.loginErrorEvent.asObserver().next { [unowned self] error in
////            self.showAlert(for: error)
////        }.disposed(by: bag)
//    }
//
//    private func rxDataSource() -> RxCollectionViewSectionedReloadDataSource<BooksSectionViewModel> {
//        let dataSource = RxCollectionViewSectionedReloadDataSource<BooksSectionViewModel>(
//            configureCell: { (dataSource, collectionView, indexPath, item) in
//                switch item {
//                case .action(let name):
////                    let actionCell = collectionView.dequeue(cellType: AddMusicServiceCell.self, for: indexPath)
////                    actionCell.populate(action: name)
////                    return actionCell
//
//                    let drillInCell = collectionView.dequeue(cellType: SettingDrillInCell.self, for: indexPath)
//                    drillInCell.populate(heading: name)
//                    return drillInCell
//
//                }},
//            configureSupplementaryView: { _, collectionView, kind, indexPath in
//                return collectionView.dequeueReusableSupplementaryView(
//                    ofKind: kind,
//                    withReuseIdentifier: UICollectionReusableView.identifierName,
//                    for: indexPath)
//        })
//        return dataSource
//    }
}

extension MainViewController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModelSections.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModelSections[section].items.count
    }
    
    // This strategy for self sizing cells involves constraining each cell's width
    // to the collection view width, so that the cell can solve for it's required height.
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let preferredWidth = collectionView.bounds.width
        let item = viewModelSections[indexPath.section].items[indexPath.item]
        switch item {
//        case let .header(title, subTitle):
//            let headerCell = collectionView.dequeue(cellType: DeviceGroupHeaderCell.self, for: indexPath)
//            headerCell.populate(title: title, subtitle: subTitle)
//            headerCell.setWidth(preferredWidth)
//            return headerCell
//        case let .nowPlaying(trackInfo):
//            let nowPlayingCell = collectionView.dequeue(cellType: DeviceGroupNowPlayingCell.self, for: indexPath)
//            nowPlayingCell.populate(trackInfoViewModel: trackInfo)
//            nowPlayingCell.setWidth(preferredWidth)
//            return nowPlayingCell
        case let .drillIn(_, iconName, title, showBottomSeparator):
            let drillInCell = collectionView.dequeue(cellType: DeviceGroupSelectionCell.self, for: indexPath)
            drillInCell.populate(iconName: iconName, label: title, showBottomSeparator: showBottomSeparator)
            drillInCell.setWidth(preferredWidth)
            return drillInCell
        }
    }
}

extension MainViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectItemEvent.onNext(indexPath)
    }
}

//extension MainViewController: UICollectionViewDelegateFlowLayout {
//    public func collectionView(_ collectionView: UICollectionView,
//                               layout collectionViewLayout: UICollectionViewLayout,
//                               sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: collectionView.bounds.width * 295 / 375, height: 140.0)
//    }
//    public func collectionView(_ collectionView: UICollectionView,
//                               layout collectionViewLayout: UICollectionViewLayout,
//                               referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: collectionView.bounds.width * 0.5, height: 100.0)
//    }
//}

