import MagazineLayout
import UIKit

//public struct DownloadStateTitleConstants {
//    static let cancelFile = "cancel-ex-1" // fa-times (Aliases: fa-remove, fa-close)
//    static let completedFile = "completed-check-1" // fa-check
//    static let errorRetryFile = "retry" // fa-check
//}
//
//public struct AnimationImageTitleConstants {
//    static let waveAnimationFrame1 = "wave-anim-frame-1"
//    static let waveAnimationFrame2 = "wave-anim-frame-2"
//    static let waveAnimationFrame3 = "wave-anim-frame-3"
//    static let waveAnimationFrame4 = "wave-anim-frame-4"
//    static let waveAnimationFrame5 = "wave-anim-frame-5"
//}

final class MediaItemDetailsCell: MagazineLayoutCollectionViewCell {
//    static let mediaItemCellUserDidTapMoreNotification = Notification.Name("mediaItemCellUserDidTapMoreNotification")
//    static let mediaItemCellUserDidTapCancelNotification = Notification.Name("mediaItemCellUserDidTapCancelNotification")
//    static let mediaItemCellUserDidTapRetryNotification = Notification.Name("mediaItemCellUserDidTapRetryNotification")
    
    // MARK: Private

    /*
 self.downloadChar = @"\uf0ed"; // fa-cloud-download
 self.cancelChar = @"\uf00d"; // fa-times (Aliases: fa-remove, fa-close)
 self.pauseChar = @"\uf04c"; // fa-pause
 self.resumeChar = @"\uf021"; // fa-refresh
 self.completedChar = @"\uf00c"; // fa-check
 self.errorChar = @"\uf0e7"; // fa-bolt (Aliases: fa-flash)
 self.cancelledChar = @"\uf05e"; // fa-ban
*/

    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var presenterLabel: UILabel!
    @IBOutlet private weak var presentedAtLabel: UILabel!
    @IBOutlet private weak var separatorView: UIView!

    var playable: Playable? = nil
    
    // MARK: Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        let notificationCenter = NotificationCenter.default
//        notificationCenter.addObserver(self, selector: #selector(MediaItemDetailsCell.handleCurrentAssetDidChangeNotification(notification:)), name: AssetPlaybackManager.currentAssetDidChangeNotification, object: nil)
        
    }

    deinit {
        
    }
    
    // MARK: Internal
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        contentView.backgroundColor = nil
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
//    func set(uuid: String, title: String, presenter: String, showBottomSeparator: Bool) {
    func set(playable: Playable, title: String, presenter: String, showBottomSeparator: Bool, showTitle: Bool) {
//        titleLabel.text = text
        self.playable = playable
        
        titleLabel.text = title
        titleLabel.isHidden = !showTitle

        presenterLabel.text = presenter
        if let mediaItem: MediaItem = playable as? MediaItem,
            let presentedAt: TimeInterval = mediaItem.presentedAt {

            let presentedDate: Date = Date(timeIntervalSince1970: presentedAt)
            
            let dateFormat: DateFormatter = DateFormatter()
            dateFormat.timeStyle = .none
            dateFormat.dateStyle = .medium
//            let locale: Locale = Locale()
            dateFormat.locale = Locale(identifier: "en_US_POSIX")
            
            presentedAtLabel.text = dateFormat.string(from: presentedDate)
        } else {
            presentedAtLabel.text = NSLocalizedString("Unknown presentation date", comment: "").l10n()
        }
        separatorView.isHidden = !showBottomSeparator
        
        contentView.backgroundColor = UIColor.white
        
        artworkImageView.layer.cornerRadius = 5
        artworkImageView.layer.masksToBounds = true
        artworkImageView.layer.borderWidth = 0

        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    

    @IBAction func handleMoreButtonTap(_ sender: Any) {
//            NotificationCenter.default.post(name: MediaItemDetailsCell.mediaItemCellUserDidTapMoreNotification, object: playable)
    }

    @IBAction func handleDownloadStateButtonTap(_ sender: Any) {

//        if self.downloadStateButton.image(for: .normal) == UIImage(named: DownloadStateTitleConstants.cancelFile) {
//            NotificationCenter.default.post(name: MediaItemDetailsCell.mediaItemCellUserDidTapCancelNotification, object: playable)
//        } else if self.downloadStateButton.image(for: .normal) == UIImage(named: DownloadStateTitleConstants.errorRetryFile) {
//            NotificationCenter.default.post(name: MediaItemDetailsCell.mediaItemCellUserDidTapRetryNotification, object: playable)
//        }
    }

    @objc func handleCurrentAssetDidChangeNotification(notification: Notification) {
        DDLogDebug("notification: \(notification)")
//        if let fileDownload: FileDownload = notification.object as? FileDownload,
//            let downloadAsset: Asset = self.downloadAsset.value {
//            DDLogDebug("initiateNotification filedownload: \(fileDownload)")
//            if fileDownload.localUrl.lastPathComponent == downloadAsset.uuid.appending(String(describing: ".\(downloadAsset.fileExtension)")) {
//
//                self.downloadState.onNext(.initiating)
//            }
//
//        }
    }

}
