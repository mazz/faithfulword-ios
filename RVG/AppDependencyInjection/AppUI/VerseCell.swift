import UIKit

class VerseCell: UICollectionViewCell {
    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var chapterAndVerse: UILabel!

    // MARK: Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
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

    public func populate(with body: String, chapterAndVerse: String) {
        self.body.text = body
        self.chapterAndVerse.text = chapterAndVerse
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}
