import Foundation
import RxSwift
import Moya

public extension PrimitiveSequenceType where TraitType == SingleTrait {
    /// Map to a `Single` of `Void`
    ///
    /// - Returns: A `Void` `Single` that completes on the receiver's completion.
    public func toVoid() -> Single<Void> {
        return map { _ in () }
    }
}



public enum GeneralError: Error {
    case unexpectedNil
}

public extension PrimitiveSequenceType where TraitType == SingleTrait, ElementType: OptionalType {
    public func completeNil() -> Single<ElementType.WrappedType> {
        return map { element in
            if let value = element.value { return value }
            throw GeneralError.unexpectedNil
        }
    }
}

/// Errors during network response handling.
///
/// - httpError: Relates to HTTP status codes.
public enum AppResponseError: Error, LocalizedError {
    case httpError(code: Int, message: String)
    
    public var errorDescription: String? {
        switch self {
        case .httpError(let code, let message): return "HTTP Error \(code): \(message)"
        }
    }
}

public extension PrimitiveSequence where TraitType == SingleTrait, E: Response {
    
    /// Attempt parsing json to a given type.
    ///
    /// - Parameter type: The codable type to parse to.
    /// - Returns: Single of parsed types.
    public func parse<T: Codable>(type: T.Type) -> Single<T> {
        return checkStatusCode()
            .map { try JSONDecoder().decode(type, from: $0.data) }
    }
    
    /// Ensure a request's response is "OK"
    ///
    /// - Returns: Single with the same response
    public func checkStatusCode() -> Single<E> {
        return map { response in
            if (200..<300).contains(response.statusCode) { return response }
            
            throw AppResponseError.httpError(
                code: response.statusCode,
                message: response.data.utf8String ?? "Could not retrieve error message."
            )
        }
    }
}
