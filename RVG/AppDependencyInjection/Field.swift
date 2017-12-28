import RxSwift

/// Our own type mimicking RxSwift's, now deprecated, `Variable`.
public final class Field<T> {
    
    // MARK: Fields
    
    // using a ReplaySubject instead of PublishSubject
    // because ReplaySubject avoids a re-entrancy anomaly deep in Rx
    private let subject = ReplaySubject<T>.create(bufferSize: 1)
    private let bag = DisposeBag()
    
    // push(value) must be done for all init() functions
    public init(_ value: T) {
        push(value)
    }
    
    public init(value: T, observable: Observable<T>) {
        push(value)
        observable.bind(to: subject).disposed(by: bag)
    }
    
    // MARK: API
    
    public var value: T {
        get {
            // Safe to force unwrap this because the `subject` will always have a cached
            // event since we cache it on `init`. Also, the event coming into the
            // subscription to it will run synchronously because `ReplaySubject` emits
            // immediately when subscribed to (as it has a cached event).

            var result: T?
            subject.take(1).next { value in
                result = value
            }.disposed(by: bag)
            
            return result!
        }
        set { push(newValue) }
    }
    
    public func asObservable() -> Observable<T> {
        return subject.asObservable()
    }
    
    // MARK: Helpers
    
    private func push(_ value: T) {
        subject.onNext(value)
    }
}
