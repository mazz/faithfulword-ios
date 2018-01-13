import Foundation
import RxSwift
import RxCocoa
import RxDataSources

public final class MediaListingViewController: UIViewController {
    // MARK: View
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: Dependencies
    
    internal var viewModel: MediaListingViewModel!
    
    // MARK: Fields
    private var viewModelSections: [BooksSectionViewModel] = []
    private let bag = DisposeBag()
    
    // MARK: Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(cellType: DeviceGroupSelectionCell.self)
//        collectionView.delegate = self
//        collectionView.dataSource = self
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize
        
        //        registerReusableViews()
        //        bindToViewModel()
//        reactToViewModel()
//        reactToContentSizeChange()
    }    
}
