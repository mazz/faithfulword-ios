import UIKit
//import BoseMobileUtilities

public final class SuggestedNameCell: UICollectionViewCell {

    @IBOutlet private weak var suggestedNameLabel: UILabel!
    @IBOutlet private weak var labelBackgroundView: UIView!
    @IBOutlet private weak var labelBackgroundBorderView: UIView!
    @IBOutlet private weak var checkmarkImageView: UIImageView!
    @IBOutlet private weak var borderWidthConstraint: NSLayoutConstraint!
    
    override public func awakeFromNib() {
        super.awakeFromNib()
//        suggestedNameLabel.font = UIFont.boseFont(.book, .body)
    }

    public func populate(with title: String) {
        suggestedNameLabel.text = title
    }
    
    public override var bounds: CGRect {
        didSet {
            labelBackgroundView.layer.cornerRadius = bounds.height / 2 - borderWidthConstraint.constant
            labelBackgroundBorderView.layer.cornerRadius = bounds.height / 2
        }
    }
    
    public override var isSelected: Bool {
        didSet {
            if isSelected {
                labelBackgroundView.backgroundColor = UIColor.white
                checkmarkImageView.isHidden = false
                labelBackgroundBorderView.backgroundColor = UIColor.black
            } else {
                labelBackgroundView.backgroundColor = UIColor.gray
                checkmarkImageView.isHidden = true
                labelBackgroundBorderView.backgroundColor = UIColor.gray
            }
        }
    }
}
