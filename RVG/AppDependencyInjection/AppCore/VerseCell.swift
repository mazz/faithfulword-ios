import UIKit

class VerseCell: UICollectionViewCell {
    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var chapterAndVerse: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    public func populate(with body: String, chapterAndVerse: String) {
        self.body.text = body
        self.chapterAndVerse.text = chapterAndVerse
    }
}
