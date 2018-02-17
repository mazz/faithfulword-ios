import UIKit

final class RadioSelectionCell: UICollectionViewCell {

    // MARK: View
    
//    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var radioSelectionLabel: UILabel!
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var topDividerView: UIView!

    
    private lazy var widthConstraint: NSLayoutConstraint? = { [unowned self] in
        self.contentView.widthAnchor.constraint(equalToConstant: 0)
    }()
    
    // MARK: Lifecycle
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        styleCell()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
//        iconImageView.image = nil
        radioSelectionLabel.text = nil
        
        self.widthConstraint?.isActive = false
    }

    internal func setTopDivider(hidden: Bool) {
        topDividerView.isHidden = hidden
    }

    // MARK: Public
    
    public func populate(with: String) {
//        iconImageView.image = UIImage.uiAsset(name: iconName)
        radioSelectionLabel.text = with
//        separatorView.isHidden = !showBottomSeparator
    }
    
    public func setWidth(_ width: CGFloat) {
        self.widthConstraint?.constant = width
        self.widthConstraint?.isActive = true
    }
    
    // MARK: Private
    
    private func styleCell() {
        backgroundColor = UIColor.white
    }

    private func clearContents() {
//        titleLabel.text = nil
        topDividerView.isHidden = true
    }

}
