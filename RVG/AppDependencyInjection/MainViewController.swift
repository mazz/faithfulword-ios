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
    
    private let bag = DisposeBag()
    
    // MARK: Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        registerReusableViews()
        bindToViewModel()
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
    
    private func bindToViewModel() {
        collectionView.rx.setDelegate(self).disposed(by: bag)
        viewModel.sections.asObservable()
            .bind(to: collectionView.rx.items(dataSource: rxDataSource()))
            .disposed(by: bag)
        collectionView.rx.itemSelected.asObservable()
            .subscribe(viewModel.selectItemEvent.asObserver())
            .disposed(by: bag)
//        viewModel.loginErrorEvent.asObserver().next { [unowned self] error in
//            self.showAlert(for: error)
//        }.disposed(by: bag)
    }
    
    private func rxDataSource() -> RxCollectionViewSectionedReloadDataSource<BooksSectionViewModel> {
        let dataSource = RxCollectionViewSectionedReloadDataSource<BooksSectionViewModel>(
            configureCell: { (dataSource, collectionView, indexPath, item) in
                switch item {
                case .action(let name):
//                    let actionCell = collectionView.dequeue(cellType: AddMusicServiceCell.self, for: indexPath)
//                    actionCell.populate(action: name)
//                    return actionCell
                    
                    let drillInCell = collectionView.dequeue(cellType: SettingDrillInCell.self, for: indexPath)
                    drillInCell.populate(heading: name)
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
        return CGSize(width: collectionView.bounds.width * 295 / 375, height: 140.0)
    }
//    public func collectionView(_ collectionView: UICollectionView,
//                               layout collectionViewLayout: UICollectionViewLayout,
//                               referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: collectionView.bounds.width * 0.5, height: 100.0)
//    }
}
