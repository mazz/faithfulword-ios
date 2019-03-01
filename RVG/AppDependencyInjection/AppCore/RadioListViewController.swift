import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

public final class RadioListViewController: UIViewController {
    
    // MARK: View
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    // MARK: Dependencies
    
    public var viewModel: RadioListViewModeling!
    
    // MARK: Fields
    
    private let bag = DisposeBag()
    
    // MARK: Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        registerReusableViews()
        bindToViewModel()
    }
    
    private func registerReusableViews() {
        collectionView.register(cellType: RadioSelectionCell.self, in: ModuleInfo.bundle)
    }
    
    private func bindToViewModel() {
        collectionView.rx.setDelegate(self).disposed(by: bag)
        viewModel.sections.asObservable()
            .bind(to: collectionView.rx.items(dataSource: rxDataSource()))
            .disposed(by: bag)
        collectionView.rx.itemSelected.asObservable()
            .bind(to: viewModel.selectionEvent)
            .disposed(by: bag)
        viewModel.title
            .bind(to: rx.title)
            .disposed(by: bag)
        viewModel.errorEvent
            .next { [unowned self] error in
                self.showAlert(for: error)
            }
            .disposed(by: bag)
    }
    
    private func rxDataSource() -> RxCollectionViewSectionedReloadDataSource<RadioListSectionViewModel> {
        let dataSource = RxCollectionViewSectionedReloadDataSource<RadioListSectionViewModel>(
            configureCell: { (dataSource, collectionView, indexPath, item) in
                switch item {
                case let .selectable(title, isSelected):
                    let radioSelectionCell = collectionView.dequeue(cellType: RadioSelectionCell.self, for: indexPath)
                    radioSelectionCell.populate(with: title)
                    radioSelectionCell.setTopDivider(hidden: indexPath.item == 0)
                    radioSelectionCell.isSelected = isSelected
                    return radioSelectionCell
                }
        }, configureSupplementaryView: { _, collectionView, kind, indexPath in
                return collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: UICollectionReusableView.identifierName,
                    for: indexPath)
        })
        return dataSource
    }
}

extension RadioListViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let preferredWidth: CGFloat = collectionView.bounds.width
        
        switch viewModel.item(at: indexPath) {
        case let .selectable(title, _):
            guard let view = try? UIView.sizingView(for: RadioSelectionCell.self,
                                                    bundle: ModuleInfo.bundle) else { return CGSize(width: 0.1, height: 0.1) }
            view.populate(with: title)
            return CGSize(width: preferredWidth, height: view.height(for: preferredWidth))
        }
    }
}

extension RadioListViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //        DDLogDebug("scrollViewDidEndDecelerating scrollView: \(scrollView)")
        
        let offsetDiff: CGFloat = scrollView.contentSize.height - scrollView.contentOffset.y
        //        DDLogDebug("offset diff: \(offsetDiff)")
        DDLogDebug("near bottom: \(offsetDiff - collectionView.frame.size.height)")
        //        if scrollView.contentSize.height - scrollView.contentOffset.y <
        
        if offsetDiff - collectionView.frame.size.height <= 20.0 {
            DDLogDebug("fetch!")
            viewModel.fetchMoreItems()
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //        DDLogDebug("scrollViewDidEndDragging scrollView: \(scrollView)")
        
        let offsetDiff: CGFloat = scrollView.contentSize.height - scrollView.contentOffset.y
        //        DDLogDebug("offset diff: \(offsetDiff)")
        DDLogDebug("near bottom: \(offsetDiff - collectionView.frame.size.height)")
        
        if offsetDiff - collectionView.frame.size.height <= 20.0 {
            DDLogDebug("fetch!")
            viewModel.fetchMoreItems()
        }
    }
}
