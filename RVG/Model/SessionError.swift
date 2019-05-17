
import Foundation

enum SessionError : Error {
    case urlNotReachable
    case urlLoadFailed
    case dataTask(String)
    case jsonParseFailed
}
