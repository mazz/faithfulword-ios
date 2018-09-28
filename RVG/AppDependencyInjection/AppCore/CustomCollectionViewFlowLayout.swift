import UIKit

// custom layout that invalidates all headers in sections so that they can layout according to new size
public final class CustomCollectionViewFlowLayout: UICollectionViewFlowLayout {

    // When using more than one section, the subsequent section headers were being positioned
    // over top of the items, instead of in the gap that had been calculated for them.
    // This makes it so that as a regular cell position is being invalidated, it's
    // corresponding header becomes invalidated as well.
    // Also, invalidate any section headers for sections lacking items, since there would
    // be no call to here to invalidate an item to then invalidate the header.
    override public func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
        
        var sectionIndexPaths = [originalAttributes.indexPath]
        if let collectionView = self.collectionView {
            for sectionIndex in 0 ..< collectionView.numberOfSections
                where collectionView.numberOfItems(inSection: sectionIndex) == 0 {
                sectionIndexPaths.append(IndexPath(item: 0, section: sectionIndex))
            }
        }
        context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader, at: sectionIndexPaths)
        return context
    }
}
