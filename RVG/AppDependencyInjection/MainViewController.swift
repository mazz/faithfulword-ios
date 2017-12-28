import UIKit
import RxSwift
import RxCocoa
//import BoseMobileModels
//import BoseMobileCommunication
//import BoseMobileUI

internal final class MainViewController: UIViewController {
    
    // MARK: View
    
//    @IBOutlet private weak var sectionalNavigatorContainer: UIView!
//    @IBOutlet private weak var deviceNowPlayingBarContainerView: UIView!
//    @IBOutlet private weak var nowPlayingBarButton: UIButton!
//    @IBOutlet private weak var controlCentreButton: UIButton!
    
    // MARK: Fields
    
//    private let nowPlayingBar = DeviceNowPlayingBarView.fromUiNib()
    private let bag = DisposeBag()
    
    // MARK: Dependencies
    
    internal var viewModel: MainViewModel!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        embedNowPlayingBar()
//        styleView()
        bindToViewModel()
//        nowPlayingBarButton.rx.tap.asObservable()
//            .bind(to: viewModel.nowPlayingDetailsEvent)
//            .disposed(by: bag)
    }
    
    // MARK: Public
    
    public func plant(_ sectionalNavigatorViewController: UIViewController) {
        viewSafe { [unowned self] in
//            self.embed(sectionalNavigatorViewController,
//                       in: self.sectionalNavigatorContainer)
        }
    }
    
    // MARK: Private helpers
    
//    private func embedNowPlayingBar() {
//        deviceNowPlayingBarContainerView.embedFilling(subview: nowPlayingBar)
//    }
//
//    private func styleView() {
//        navigationItem.title = String.fetch(Localizable.deviceSelectDeviceTitleText)
//    }
    
    private func bindToViewModel() {
//        viewModel.deviceName
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
    
}
