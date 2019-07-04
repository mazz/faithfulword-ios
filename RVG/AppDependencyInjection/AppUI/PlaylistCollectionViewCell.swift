import MagazineLayout
import UIKit

final class PlaylistCollectionViewCell: MagazineLayoutCollectionViewCell {
    
    // MARK: Private
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var groupSelectionLabel: UILabel!
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var chevronImageView: UIImageView!
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var presenterLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playStateImageView: UIImageView!
    
    // MARK: Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: Internal
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
//        titleLabel.text = nil
//        contentView.backgroundColor = nil
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    // MARK: Public
    
    public func populate(iconName: String, label: String, showBottomSeparator: Bool, showChevron: Bool = true) {
        iconImageView.image = UIImage.uiAsset(name: iconName)
        iconImageView.layer.cornerRadius = 5
        iconImageView.layer.masksToBounds = true
        iconImageView.layer.borderWidth = 0

        groupSelectionLabel.text = label
        separatorView.isHidden = !showBottomSeparator
        chevronImageView.isHidden = !showChevron

        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
//    
//    func set(title: String, presenter: String) {
//        //        titleLabel.text = text
//        presenterLabel.text = presenter
//        titleLabel.text = title
//        
//        
//        contentView.backgroundColor = UIColor.white
//        self.setNeedsLayout()
//        self.layoutIfNeeded()
//    }
}
