import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class BibleLanguageViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: Dependencies

    internal var viewModel: BibleLanguageViewModel!

    // MARK: Fields

    private var viewModelSections: [BibleLanguageSectionViewModel] = []
    private let bag = DisposeBag()

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false

        registerReusableViews()
        bindToViewModel()
        reactToViewModel()
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
        collectionView.register(cellType: VerseCell.self)
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

    private func rxDataSource() -> RxCollectionViewSectionedReloadDataSource<BibleLanguageSectionViewModel> {
        let dataSource = RxCollectionViewSectionedReloadDataSource<BibleLanguageSectionViewModel>(
            configureCell: { (dataSource, collectionView, indexPath, item) in
                switch item {
                case let .language(_, body):
                    print(".language")
//                case let .drillIn(_, iconName, title, showBottomSeparator):
                    let drillInCell = collectionView.dequeue(cellType: DeviceGroupSelectionCell.self, for: indexPath)
                    drillInCell.populate(iconName: "iconName", label: "title", showBottomSeparator: true)
                    return drillInCell
//                case let .quote(body, chapterAndVerse):
//                    let verseCell = collectionView.dequeue(cellType: VerseCell.self, for: indexPath)
//                    verseCell.populate(with: body, chapterAndVerse: chapterAndVerse)
//                    return verseCell
                } },
            configureSupplementaryView: { _, collectionView, kind, indexPath in
                return collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: UICollectionReusableView.identifierName,
                    for: indexPath)
        })
        return dataSource
    }
}

extension BibleLanguageViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let preferredWidth: CGFloat = collectionView.bounds.width

        switch viewModel.item(at: indexPath) {
        case let .language(_, body):
            guard let view = try? UIView.sizingView(for: VerseCell.self,
                                                    bundle: ModuleInfo.bundle) else { break }
            view.populate(with: body, chapterAndVerse: "test")
            return CGSize(width: preferredWidth, height: view.height(for: preferredWidth))
        }
        return CGSize(width: 0.1, height: 0.1)
    }
}

