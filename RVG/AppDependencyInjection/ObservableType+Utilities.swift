import RxSwift

public extension ObservableType {
    
    /// Type-inferred version of `filterMap<T>(to type: T.Type, _ transform: @escaping (Self.E) -> Any?) -> RxSwift.Observable<T>`
    ///
    /// - Parameter transform: The transform mapping to what your speculated type.
    /// - Returns: Observable emitting only the mapped type.
    public func filterMap<T>(_ transform: @escaping (Self.E) throws -> Any?) -> RxSwift.Observable<T> {
        return filterMap(to: T.self, transform)
    }
    
    /// Filters out failed outcomes of mapping to a specified type.
    ///
    /// - Parameters:
    ///   - type: The type to map to (i.e. the type you want to enforce).
    ///   - transform: The transform mapping to what your speculated type.
    /// - Returns: Observable emitting only the mapped type.
    public func filterMap<T>(to type: T.Type, _ transform: ((Self.E) throws -> Any?)? = nil) -> RxSwift.Observable<T> {
        return map { item -> T? in
            if transform == nil {
                return item as? T
            }
            return try transform?(item) as? T
            }
            .filterNils()
    }
    
    /// Short-hand for `subscribe(onNext: { ... })`
    ///
    /// - Parameter action: Action to perform on next.
    /// - Returns: Disposable from next subscription.
    public func next(_ action: @escaping (Self.E) -> Void) -> Disposable {
        return subscribe(onNext: { value in
            action(value)
        })
    }
    
    /// Subscribe and dispose with bag.
    /// Useful for cold-signals that require subscription trigger.
    ///
    /// - Parameter bag: The bag to dispose subscription on.
    public func subscribeAndDispose(by bag: DisposeBag) {
        subscribe().disposed(by: bag)
    }
    
    /// Map to an `Observable` of `Void`
    ///
    /// - Returns: A `Void` `Observable`.
    public func toVoid() -> RxSwift.Observable<Void> {
        return map { _ in () }
    }
}

public extension ObservableType where E: OptionalType {
    
    /// Filters out nil values in an event chain.
    ///
    /// - Returns: Observable emitting only non-nil unwrapped values.
    public func filterNils() -> RxSwift.Observable<E.WrappedType> {
        return filter { $0.value != nil }
            .map { $0.value! }
    }
    
    /// Perform task on nil value in event chain & return unwrapping sequence.
    ///
    /// - Parameter perform: Task to be performed on nil value.
    /// - Returns: Observable emitting only non-nil unwrapped values.
    public func onNil(_ perform: @escaping () -> Void) -> RxSwift.Observable<E.WrappedType> {
        return self.do(onNext: { wrapped in
            if wrapped.value == nil {
                perform()
            }
        }).filterNils()
    }
}
