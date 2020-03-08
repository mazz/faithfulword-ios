import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import MagazineLayout

public final class SideMenuViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModelSections.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewModelSections.count == 0 {
            return 0
        }
        return viewModelSections[section].items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        DDLogDebug("viewModelSections[0].items[indexPath.row]: \(viewModelSections[indexPath.section].items[indexPath.row])")
        //        }
        let item: SideMenuItemType = viewModelSections[indexPath.section].items[indexPath.row]
        
        switch item {
        case let .drillIn(_, iconName, title, showBottomSeparator):
            let drillInCell = collectionView.dequeueReusableCell(withReuseIdentifier: DeviceGroupSelectionCell.description(), for: indexPath) as! DeviceGroupSelectionCell
            drillInCell.populate(iconName: iconName, label: title, showBottomSeparator: showBottomSeparator, showChevron: true)
//            drillInCell.setWidth(200)
            return drillInCell
        case let .quote(body, chapterAndVerse):
            let verseCell = collectionView.dequeueReusableCell(withReuseIdentifier: VerseCell.description(), for: indexPath) as! VerseCell
            verseCell.populate(with: body, chapterAndVerse: chapterAndVerse)
            return verseCell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectItemEvent.onNext(indexPath)
    }
    
    // MARK: View
    
    private lazy var collectionView: UICollectionView = {
        let layout = MagazineLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(UINib(nibName: "DeviceGroupSelectionCell", bundle: nil), forCellWithReuseIdentifier: DeviceGroupSelectionCell.description())
        collectionView.register(UINib(nibName: "VerseCell", bundle: nil), forCellWithReuseIdentifier: VerseCell.description())
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

    internal var viewModel: SideMenuViewModel!

    // MARK: Fields

    private var viewModelSections: [SideMenuSectionViewModel] = []
    private let bag = DisposeBag()

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

                self.collectionView.reloadData()
            }.disposed(by: bag)
    }

//    private func registerReusableViews() {
//        collectionView.register(cellType: DeviceGroupSelectionCell.self)
//        collectionView.register(cellType: VerseCell.self)
//    }
//
//    private func bindToViewModel() {
//        collectionView.rx.setDelegate(self).disposed(by: bag)
//        viewModel.sections.asObservable()
//            .bind(to: collectionView.rx.items(dataSource: rxDataSource()))
//            .disposed(by: bag)
//        collectionView.rx.itemSelected.asObservable()
//            .subscribe(viewModel.selectItemEvent.asObserver())
//            .disposed(by: bag)
//    }

//    private func rxDataSource() -> RxCollectionViewSectionedReloadDataSource<SideMenuSectionViewModel> {
//        let dataSource = RxCollectionViewSectionedReloadDataSource<SideMenuSectionViewModel>(
//            configureCell: { (dataSource, collectionView, indexPath, item) in
//                switch item {
//                case let .drillIn(_, iconName, title, showBottomSeparator):
//                    let drillInCell = collectionView.dequeue(cellType: DeviceGroupSelectionCell.self, for: indexPath)
//                    drillInCell.populate(iconName: iconName, label: title, showBottomSeparator: showBottomSeparator)
//                    return drillInCell
//                case let .quote(body, chapterAndVerse):
//                    let verseCell = collectionView.dequeue(cellType: VerseCell.self, for: indexPath)
//                    verseCell.populate(with: body, chapterAndVerse: chapterAndVerse)
//                    return verseCell
//                } },
//            configureSupplementaryView: { _, collectionView, kind, indexPath in
//                return collectionView.dequeueReusableSupplementaryView(
//                    ofKind: kind,
//                    withReuseIdentifier: UICollectionReusableView.identifierName,
//                    for: indexPath)
//            })
//        return dataSource
//    }
}

extension SideMenuViewController: UICollectionViewDelegateFlowLayout {
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
        case let .quote(body, chapterAndVerse):
            guard let view = try? UIView.sizingView(for: VerseCell.self,
                                                    bundle: ModuleInfo.bundle) else { break }
            view.populate(with: body, chapterAndVerse: chapterAndVerse)
            return CGSize(width: preferredWidth, height: view.height(for: preferredWidth))
        }
        return CGSize(width: 0.1, height: 0.1)
    }
}


// MARK: UICollectionViewDelegateMagazineLayout

extension SideMenuViewController: UICollectionViewDelegateMagazineLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeModeForItemAt indexPath: IndexPath) -> MagazineLayoutItemSizeMode {
//        return MagazineLayoutItemSizeMode(widthMode: .fullWidth(respectsHorizontalInsets: true), heightMode: .dynamic)
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
        return 30
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, verticalSpacingForElementsInSectionAtIndex index: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForSectionAtIndex index: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 40)
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsForItemsInSectionAtIndex index: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 40)
        return UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
    }
}

