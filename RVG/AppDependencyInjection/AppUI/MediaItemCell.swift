import MagazineLayout
import UIKit

final class MediaItemCell: MagazineLayoutCollectionViewCell {

    // MARK: Private


    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var presenterLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var playStateImageView: UIImageView!
    
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
    
    func set(title: String, presenter: String, showBottomSeparator: Bool) {
//        titleLabel.text = text
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
}
