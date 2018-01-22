import UIKit

/// Reuseable collection view cell with two labels and a chevron
public final class SettingDrillInCell: UICollectionViewCell {

    // MARK: View
    
    @IBOutlet private weak var topDivider: UIView!
    @IBOutlet private weak var headingLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!
    
    // Only set by SettingDrillInCellStacked.xib, not by SettingDrillInCell.xib
    @IBOutlet private weak var stackedVerticalSpaceBetweenLabels: NSLayoutConstraint?
    
    private lazy var widthConstraint: NSLayoutConstraint? = { [unowned self] in
        self.contentView.widthAnchor.constraint(equalToConstant: 0)
    }()
    
    // MARK: Public
    
    public func populate(heading: String, value: String? = nil) {
        assert(!heading.isEmpty, "Setting Drill-in heading is empty")
        
        headingLabel.text = heading
        valueLabel.text = value
        
        if #available(iOS 11, *) {} else {
            updateFont()
        }
        
        // When stacked, and not showing the value, remove the space between the header and value
        stackedVerticalSpaceBetweenLabels?.constant = value.isNilOrEmpty ? 0 : 10
    }
    
    public func setTopDivider(hidden: Bool) {
        topDivider.isHidden = hidden
    }

    public func setWidth(_ width: CGFloat) {
        self.widthConstraint?.constant = width
        self.widthConstraint?.isActive = true
    }
    
    // MARK: Lifecycle
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        styleCell()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        headingLabel.text = nil
        valueLabel.text = nil
        
        self.widthConstraint?.isActive = false
    }
    
    // MARK: Private
    private func styleCell() {
//        if #available(iOS 11, *) {
//            headingLabel.font = UIFont.boseAutoRescalingFont(.book, .caption1)
//            valueLabel.font = UIFont.boseAutoRescalingFont(.book, .caption1)
//        } else {
//            updateFont()
//        }
//
//        headingLabel.textColor = UIColor.boseBlackCellText
//        valueLabel.textColor = UIColor.boseGreyCellText
//
    }
    
    private func updateFont() {
//        headingLabel.font = UIFont.boseFont(.book, .caption1)
//        valueLabel.font = UIFont.boseFont(.book, .caption1)
    }
}
