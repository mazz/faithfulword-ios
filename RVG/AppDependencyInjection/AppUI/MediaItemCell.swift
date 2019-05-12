import MagazineLayout
import UIKit

final class MediaItemCell: MagazineLayoutCollectionViewCell {

    // MARK: Private


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
        
        titleLabel.text = nil
        contentView.backgroundColor = nil
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    func set(title: String, presenter: String) {
//        titleLabel.text = text
        presenterLabel.text = presenter
        titleLabel.text = title
        
        
        contentView.backgroundColor = UIColor.white
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}
