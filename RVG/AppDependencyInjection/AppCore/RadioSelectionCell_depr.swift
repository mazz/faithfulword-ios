import UIKit

public class RadioSelectionCell_depr: UICollectionViewCell {
    
    // MARK: View
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var radioImageView: UIImageView!
    @IBOutlet private weak var topDividerView: UIView!
    
    // MARK: Lifecycle
    
    public override func awakeFromNib() {
        super.awakeFromNib()

        clearContents()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        clearContents()
    }
    
    internal func populate(with title: String) {
        self.titleLabel.text = title
    }
    
    internal func setTopDivider(hidden: Bool) {
        topDividerView.isHidden = hidden
    }
    
    public override var isSelected: Bool {
        didSet {
            radioImageView.isHighlighted = isSelected
        }
    }
    
    private func clearContents() {
        titleLabel.text = nil
        topDividerView.isHidden = true
    }
}
