import UIKit
import RxSwift
import RxCocoa
import RxDataSources

/// Add service screen
public final class MainViewController: UIViewController {
    // MARK: View
    
    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: Dependencies
    
    internal var booksViewModel: BooksViewModel!
    internal var viewModel: PlaylistViewModel!

    // MARK: Fields

    private let nowPlayingBar = DeviceNowPlayingBarView.fromUiNib()
    private var viewModelSections: [PlaylistSectionViewModel] = []
    private let bag = DisposeBag()
    
    // MARK: Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
//        embedNowPlayingBar()
        registerReusableViews()
//        viewModel.setupDatasource()
        bindToViewModel()
        reactToViewModel()
//        reactToContentSizeChange()
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

//        viewModel.title
//            .asObservable()
//            .bind(to: rx.title)
//            .disposed(by: bag)
    }

    
    private func rxDataSource() -> RxCollectionViewSectionedReloadDataSource<PlaylistSectionViewModel> {
        let dataSource = RxCollectionViewSectionedReloadDataSource<PlaylistSectionViewModel>(
            configureCell: { (dataSource, collectionView, indexPath, item) in
                switch item {
                case let .drillIn(_, iconName, title, showBottomSeparator):
                    let drillInCell = collectionView.dequeue(cellType: DeviceGroupSelectionCell.self, for: indexPath)
                    drillInCell.populate(iconName: iconName, label: title, showBottomSeparator: showBottomSeparator)
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

extension MainViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let preferredWidth: CGFloat = collectionView.bounds.width
        
        
        switch viewModel.item(at: indexPath) {
        case let .drillIn(_, iconName, title, showBottomSeparator):
            guard let view = try? UIView.sizingView(for: DeviceGroupSelectionCell.self,
                                                    bundle: ModuleInfo.bundle) else { break }
            view.populate(iconName: iconName, label: title, showBottomSeparator: showBottomSeparator)
            return CGSize(width: preferredWidth, height: view.height(for: preferredWidth))
        }
        return CGSize(width: 0.1, height: 0.1)
    }
}

extension MainViewController {
    public func plant(_ viewController: UIViewController, withAnimation animation: AppAnimations.Animatable? = nil) {
        if let residualPresentedViewController = children.first?.presentedViewController {
            residualPresentedViewController.dismiss(animated: true, completion: nil)
        }
        replace(children.first, with: viewController, in: view, withAnimation: animation)
    }
}

extension MainViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        DDLogDebug("scrollViewDidEndDecelerating scrollView: \(scrollView)")
        
        let offsetDiff: CGFloat = scrollView.contentSize.height - scrollView.contentOffset.y
//        DDLogDebug("offset diff: \(offsetDiff)")
        DDLogDebug("near bottom: \(offsetDiff - collectionView.frame.size.height)")
//        if scrollView.contentSize.height - scrollView.contentOffset.y <
        
        if offsetDiff - collectionView.frame.size.height <= 20.0 {
            DDLogDebug("fetch!")
//            viewModel.fetchMoreBooks()
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        DDLogDebug("scrollViewDidEndDragging scrollView: \(scrollView)")
        
        let offsetDiff: CGFloat = scrollView.contentSize.height - scrollView.contentOffset.y
//        DDLogDebug("offset diff: \(offsetDiff)")
        DDLogDebug("near bottom: \(offsetDiff - collectionView.frame.size.height)")
        
        if offsetDiff - collectionView.frame.size.height <= 20.0 {
            DDLogDebug("fetch!")
//            viewModel.fetchMoreBooks()
        }
    }
}
