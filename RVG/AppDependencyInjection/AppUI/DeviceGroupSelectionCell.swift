import MagazineLayout
import UIKit

final class DeviceGroupSelectionCell: MagazineLayoutCollectionViewCell {

    // MARK: View
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var groupSelectionLabel: UILabel!
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var chevronImageView: UIImageView!

    private lazy var widthConstraint: NSLayoutConstraint? = { [unowned self] in
        self.contentView.widthAnchor.constraint(equalToConstant: 0)
    }()
    
    // MARK: Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        styleCell()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        groupSelectionLabel.text = nil
        
//        self.widthConstraint?.isActive = false
        self.setNeedsLayout()
        self.layoutIfNeeded()

    }
    
    // MARK: Public
    
    public func populate(iconName: String, label: String, showBottomSeparator: Bool, showChevron: Bool = true) {
        iconImageView.image = UIImage.uiAsset(name: iconName)
        groupSelectionLabel.text = label
        separatorView.isHidden = !showBottomSeparator
        chevronImageView.isHidden = !showChevron
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    public func setWidth(_ width: CGFloat) {
        self.widthConstraint?.constant = width
        self.widthConstraint?.isActive = true
    }
    
    // MARK: Private
    
    private func styleCell() {
        backgroundColor = UIColor.white
    }
}
