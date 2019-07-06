import MagazineLayout
import UIKit

final class MediaItemCell: MagazineLayoutCollectionViewCell {
    static let mediaItemCellUserDidTapMoreNotification = Notification.Name("mediaItemCellUserDidTapMoreNotification")
    
    // MARK: Private


    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var presenterLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var playStateImageView: UIImageView!
    @IBOutlet private weak var moreButton: UIButton!

    var mediaUuid: String? = nil
    
    // MARK: Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        
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
    func set(uuid: String, title: String, presenter: String, showBottomSeparator: Bool) {
//        titleLabel.text = text
        mediaUuid = uuid
        
        presenterLabel.text = presenter
        titleLabel.text = title
        
        artworkImageView.layer.cornerRadius = 5
        artworkImageView.layer.masksToBounds = true
        artworkImageView.layer.borderWidth = 0

        separatorView.isHidden = !showBottomSeparator
        
        contentView.backgroundColor = UIColor.white
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    

    @IBAction func handleMoreButtonTap(_ sender: Any) {
            NotificationCenter.default.post(name: MediaItemCell.mediaItemCellUserDidTapMoreNotification, object: mediaUuid)
    }
}
