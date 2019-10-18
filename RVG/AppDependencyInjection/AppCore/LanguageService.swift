import Foundation
import RxSwift

protocol LanguageServicing {
    var userLanguage: Field<String> { get }
    var swappedUserLanguage: Field<String> { get }
    func updateUserLanguage(languageIdentifier: String) -> Single<String>
    func fetchUserLanguage() -> Single<String>
}

public final class LanguageService: LanguageServicing {

    // MARK: Fields
    public var userLanguage: Field<String>
    public var swappedUserLanguage: Field<String>
//    public var userLanguage: PublishSubject<String> = PublishSubject<String>()
    // MARK: Dependencies
    private let dataService: UserDataServicing    

    public init(dataService: UserDataServicing) {
        self.dataService = dataService
        userLanguage = Field("en")
        swappedUserLanguage = Field("none")
    }

    public func updateUserLanguage(languageIdentifier: String) -> Single<String> {
        return dataService.updateUserLanguage(identifier: languageIdentifier)
            .do(onSuccess: { [weak self] language in
                self?.userLanguage.value = language
            })
    }

    public func fetchUserLanguage() -> Single<String> {
        return dataService.fetchUserLanguage()
            .do(onSuccess: { [weak self] language in
                self?.userLanguage.value = language
            })
    }
}
