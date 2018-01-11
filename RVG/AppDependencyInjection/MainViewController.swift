import UIKit
import RxSwift
import RxCocoa
//import BoseMobileModels
//import BoseMobileCommunication
//import BoseMobileUI

internal final class MainViewController: UIViewController {
    
    // MARK: View
    @IBOutlet weak var collectionView: UICollectionView!
    
    //    @IBOutlet private weak var sectionalNavigatorContainer: UIView!
    //    @IBOutlet private weak var deviceNowPlayingBarContainerView: UIView!
    //    @IBOutlet private weak var nowPlayingBarButton: UIButton!
    //    @IBOutlet private weak var controlCentreButton: UIButton!
    
    // MARK: Fields
    
    //    private let nowPlayingBar = DeviceNowPlayingBarView.fromUiNib()
    private let bag = DisposeBag()
    private var cellContentLayoutStyle = CellContentLayoutStyle.undetermined
    
    // MARK: Dependencies
    
    internal var viewModel: MainViewModel!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize
        
        //        embedNowPlayingBar()
        //        styleView()
        //        bindToViewModel()
        
        registerReusableViews()
        reactToViewModel()
        reactToContentSizeChange()
        
        //        nowPlayingBarButton.rx.tap.asObservable()
        //            .bind(to: viewModel.nowPlayingDetailsEvent)
        //            .disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // iOS 10 itself adds unnecessary 64 TopContentInset, which we remove here
        if #available(iOS 11, *) {} else {
            self.collectionView.contentInset.top = 0
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        resolveUndeterminedCellContentLayoutStyle()
    }
    
    
    // MARK: Public
    
    //    public func plant(_ sectionalNavigatorViewController: UIViewController) {
    //        viewSafe { [unowned self] in
    //            self.embed(sectionalNavigatorViewController,
    //                       in: self.sectionalNavigatorContainer)
    //        }
    //    }
    
    // MARK: Private helpers
    
    private func resolveUndeterminedCellContentLayoutStyle() {
        guard cellContentLayoutStyle == .undetermined, collectionView.bounds.width != 0 else {
            return
        }
        
        let preferredWidth = collectionView.bounds.width
        
        for section in viewModel.sections.value {
            for item in section.items {
                let cell = getSizingViewCell(for: item)
                if !cell.canFitContents(inWidth: preferredWidth) {
                    cellContentLayoutStyle = .vertical
                    return
                }
            }
        }
        cellContentLayoutStyle = .horizontal
    }
    
    private func registerReusableViews() {
        //        collectionView.registerUi(headerViewType: SettingHeaderView.self)
        
        //        collectionView.registerUi(cellType: SettingActionCell.self)
        collectionView.registerUi(cellType: SettingDrillInCell.self)
        //        collectionView.registerUi(cellType: SettingFieldCell.self)
        //        collectionView.registerUi(cellType: SettingInfoCell.self)
        
        // Some cell types have a stacked variant, where sub-views are layed out vertically
        collectionView.registerUi(cellType: SettingDrillInCell.self, suffix: CellContentLayoutStyle.vertical.cellNibSuffix)
        //        collectionView.registerUi(cellType: SettingFieldCell.self, suffix: CellContentLayoutStyle.vertical.cellNibSuffix)
        //        collectionView.registerUi(cellType: SettingInfoCell.self, suffix: CellContentLayoutStyle.vertical.cellNibSuffix)
    }
    
    
    // Any change in model, could widen or narrow labels or buttons, which
    // could trigger needing to switch between CellContentLayoutStyle(s).
    private func reactToViewModel() {
        viewModel.sections.asObservable()
            .next { [unowned self] _ in
                // Re-determine if cells should be sideways or stacked
                self.cellContentLayoutStyle = .undetermined
                self.collectionView.reloadData()
                
                // With self sizing done in collectionView:cellForItemAt, the layout doesn't yet know to recalculate the layout attributes
                self.collectionView.collectionViewLayout.invalidateLayout()
            }.disposed(by: bag)
    }
    
    // Any change in content size, could widen or narrow labels or buttons, which
    // could trigger needing to switch between CellContentLayoutStyle(s).
    private func reactToContentSizeChange() {
        NotificationCenter.default.rx
            .notification(NSNotification.Name.UIContentSizeCategoryDidChange)
            .next { [unowned self] _ in
                
                // Fix for when user had scrolled down, and then changed the content size
                let topIndexPath = IndexPath(item: 0, section: 0)
                self.collectionView.scrollToItem(at: topIndexPath, at: UICollectionViewScrollPosition.top, animated: false)
                
                // Re-determine if cells should be sideways or stacked
                self.cellContentLayoutStyle = .undetermined
                self.collectionView.reloadData()
                
                // With self sizing done in collectionView:cellForItemAt, the layout doesn't yet know to recalculate the layout attributes
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
            .disposed(by: bag)
    }
}

extension MainViewController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.sections.value.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.sections.value[section].items.count
    }
    
    // This strategy for self sizing cells involves constraining each cell's width
    // to the collection view width, so that the cell can solve for it's required height.
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let preferredWidth = collectionView.bounds.width
        let item = viewModel.sections.value[indexPath.section].items[indexPath.item]
        switch item {
//        case .field(let heading, let value):
//            let fieldCell = collectionView.dequeue(cellType: SettingFieldCell.self, for: indexPath, withReuseIdentifierSuffix: cellContentLayoutStyle.cellNibSuffix)
//            fieldCell.populate(heading: heading, value: value)
//            fieldCell.setWidth(preferredWidth)
//            return fieldCell
//        case .option(let type):
//            let drillInCell = collectionView.dequeue(cellType: SettingDrillInCell.self, for: indexPath, withReuseIdentifierSuffix: cellContentLayoutStyle.cellNibSuffix)
//            drillInCell.populate(heading: type.displayString)
//            drillInCell.setTopDivider(hidden: indexPath.item == 0)
//            drillInCell.setWidth(preferredWidth)
//            return drillInCell
        case .action(let type):
            let actionCell = collectionView.dequeue(cellType: SettingDrillInCell.self, for: indexPath)
            actionCell.populate(heading: type)
            actionCell.setWidth(preferredWidth)
            
//            switch type {
//            case .logout:
//                actionCell.actionButton.rx.tap.asObservable()
//                    .bind(to: self.viewModel.logoutEvent)
//                    .disposed(by: actionCell.cellReuseBag)
//            case .updateUser:
//                actionCell.actionButton.rx.tap.asObservable()
//                    .bind(to: self.viewModel.updateUserEvent)
//                    .disposed(by: actionCell.cellReuseBag)
//            }
            return actionCell
//        case .info(let text):
//            let infoCell = collectionView.dequeue(cellType: SettingInfoCell.self, for: indexPath, withReuseIdentifierSuffix: cellContentLayoutStyle.cellNibSuffix)
//            infoCell.populate(info: text)
//            infoCell.setWidth(preferredWidth)
//            return infoCell
        }
    }
    
    // Header self sizing is done via sizing cell calculation
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
//        case UICollectionElementKindSectionHeader:
//            let headerView = collectionView.dequeue(headerViewType: SettingHeaderView.self, for: indexPath)
//            let heading = viewModel.sections.value[indexPath.section].type.displayString
//            headerView.populate(title: heading)
//            return headerView
        default:
            return UICollectionReusableView()
        }
    }
    
    // Not using UIView+Sizing's cached cells because when changing the content size
    // smaller, the cached cell would try to remain as large as before. And we can avoid
    // dealing with any memory leak implications.
    private func getSizingViewCell(for type: BookItemType) -> UICollectionViewCell {
        switch type {
//        case let .field(heading, value):
//            let cell = SettingFieldCell.fromUiNib()
//            cell.populate(heading: heading, value: value)
//            return cell
//        case .option(let type):
//            let cell = SettingDrillInCell.fromUiNib()
//            cell.populate(heading: type.displayString)
//            return cell
        case .action(let type):
            let cell = SettingDrillInCell.fromUiNib()
//            cell.populate(heading: <#T##String#>, value: <#T##String?#>)
            cell.populate(heading: type)

//            cell.populate(action: type.displayString)
            return cell
//        case .info(let text):
//            let cell = SettingInfoCell.fromUiNib()
//            cell.populate(info: text)
//            return cell
        }
    }

}

// Must give a size for each header, to indicate if they're shown or not, by giving a non-zero or zero size.
// Using an uncached sizing cell, like how the cellContentLayoutStyle calculation does for the regular cells
extension MainViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard viewModel.sections.value.count > section else { return .zero }
        
        //        let view = SettingHeaderView.fromUiNib()
        //        view.populate(title: viewModel.sections.value[section].type.displayString)
        
        let preferredWidth = collectionView.bounds.width
        let size = CGSize(width: preferredWidth, height: view.height(for: preferredWidth))
        return size
    }
}

extension MainViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        viewModel.selectItemEvent.onNext(indexPath)
    }
}
//    private func embedNowPlayingBar() {
//        deviceNowPlayingBarContainerView.embedFilling(subview: nowPlayingBar)
//    }
//
//    private func styleView() {
//        navigationItem.title = String.fetch(Localizable.deviceSelectDeviceTitleText)
//    }

private func bindToViewModel() {
    //        viewModel.books
    //            .bind(to: navigationItem.rx.title)
    //            .disposed(by: bag)
    //
    //        nowPlayingBar.bind(to: viewModel.nowPlayingViewModel)
    //
    //        viewModel.deviceImageNameEvent
    //            .map { UIImage(named: $0) }
    //            .bind(to: controlCentreButton.rx.image(for: .normal))
    //            .disposed(by: bag)
    //
    //        controlCentreButton.rx.tap
    //            .bind(to: viewModel.showControlCentreEvent)
    //            .disposed(by: bag)
}


