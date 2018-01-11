/// Styling to control whether UI elements within a cell will be layed out
/// horizontally (aka side-by-side), or vertically (aka stacked)
///
/// Collection views and table views may prefer to use the most compact
/// form (horizontal), and only if content does not fit, then fall-back
/// vertically arranging subviews.

public enum CellContentLayoutStyle {
    case undetermined  // should be set by default when we need to determine layout
    case horizontal
    case vertical
    
    public var cellNibSuffix: String {
        switch self {
        case .undetermined, .horizontal:
            return ""
        case .vertical:
            return "Stacked"
        }
    }
}
