/// A container which lazily instantiates and lazily re-instantiates the underlying object.
/// Useful for objects that needs state to be reset completely via deallocation, like coordinators.
public final class Resettable<T> {
    private let make: () -> T
    private var _value: T?
    
    /// The underlying instance. If called repeatedly without being reset, it will provide the same instance.
    public var value: T {
        _value = _value ?? make()
        return _value!
    }
    
    /// Initializer.
    ///
    /// - Parameter make: A closure instantiating the underlying object.
    public init(make: @escaping () -> T) {
        self.make = make
    }
    
    /// Deallocates the underlying object.
    public func reset() {
        _value = nil
    }
}
