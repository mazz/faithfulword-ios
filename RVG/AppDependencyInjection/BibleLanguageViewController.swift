import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import L10n_swift

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

    internal override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.title = NSLocalizedString("Set Bible Language", comment: "").l10n()
    }

    // MARK: Private helpers

    private func reactToViewModel() {
        viewModel.sections.asObservable()
            .next { [unowned self] sections in
                // Cache our viewModel sections, so we don't need to read the value while it' still being written to
                self.viewModelSections = sections

                self.collectionView.reloadData()
            }.disposed(by: bag)

        viewModel.chooseLanguageEvent.next { bibleLanguageLanguageType in
            switch bibleLanguageLanguageType {
            case .defaultLanguageType(let languageIdentifier):
                print("languageIdentifier: \(languageIdentifier)")
                L10n.shared.language = languageIdentifier
                self.navigationItem.title = NSLocalizedString("Set Bible Language", comment: "").l10n()
                self.title = NSLocalizedString("Set Bible Language", comment: "").l10n()
            }
        }.disposed(by: bag)
    }

    private func registerReusableViews() {
        collectionView.register(cellType: DeviceGroupSelectionCell.self)
        collectionView.register(cellType: VerseCell.self)
        collectionView.register(cellType: RadioSelectionCell.self)
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
                case let .language(_, sourceMaterial, languageIdentifier, _, isSelected):
                    print(".language")
//                    let drillInCell = collectionView.dequeue(cellType: DeviceGroupSelectionCell.self, for: indexPath)
//                    drillInCell.populate(iconName: "language_menu", label: String(sourceMaterial + " (\(languageIdentifier))"), showBottomSeparator: true)
//                    return drillInCell
                    let radioSelectionCell = collectionView.dequeue(cellType: RadioSelectionCell.self, for: indexPath)
                    radioSelectionCell.populate(with: String(sourceMaterial + " (\(languageIdentifier))"))
                    radioSelectionCell.setTopDivider(hidden: indexPath.item == 0)
                    radioSelectionCell.isSelected = isSelected
                    return radioSelectionCell
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
        case let .language(_, sourceMaterial, languageIdentifier, _, isSelected):

//            guard let view = try? UIView.sizingView(for: DeviceGroupSelectionCell.self,
//                                                    bundle: ModuleInfo.bundle) else { break }
//            view.populate(iconName: "language_menu", label: String(sourceMaterial + " (\(languageIdentifier))"), showBottomSeparator: true)
            guard let view = try? UIView.sizingView(for: RadioSelectionCell.self,
                                                    bundle: ModuleInfo.bundle) else { break }
            view.populate(with: String(sourceMaterial + " (\(languageIdentifier))"))
            return CGSize(width: preferredWidth, height: view.height(for: preferredWidth))
        }
        return CGSize(width: 0.1, height: 0.1)
    }
}


