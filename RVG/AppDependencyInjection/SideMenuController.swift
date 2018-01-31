import UIKit
import RxSwift
import RxCocoa
import RxDataSources

public final class SideMenuController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    // MARK: Fields
    
//    private var viewModelSections: [BooksSectionViewModel] = []
    private let bag = DisposeBag()

    public override func viewDidLoad() {
        
    }
}
