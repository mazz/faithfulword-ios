import Foundation

public protocol OptionalType {
    associatedtype WrappedType
    var value: WrappedType? { get }
}

extension Optional: OptionalType {
    public var value: Wrapped? {
        return self
    }
}

public extension Optional where Wrapped == String {
    public var isNilOrEmpty: Bool {
        switch self {
        case .none:
            return true
        case .some(let str):
            return str.isEmpty
        }
    }
}
