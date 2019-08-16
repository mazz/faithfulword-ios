import Foundation
import RxSwift

protocol LanguageServicing {
    var userLanguage: Field<String> { get }
    func updateUserLanguage(languageIdentifier: String) -> Single<String>
    func fetchUserLanguage() -> Single<String>
}

public final class LanguageService: LanguageServicing {

    // MARK: Fields
    public var userLanguage: Field<String>

    // MARK: Dependencies
    private let dataService: UserDataServicing

    public init(dataService: UserDataServicing) {
        self.dataService = dataService
        userLanguage = Field("en")
    }

    public func updateUserLanguage(languageIdentifier: String) -> Single<String> {
        return dataService.updateUserLanguage(identifier: languageIdentifier)
            .do(onSuccess: { identifier in
                self.userLanguage.value = identifier
            })
    }

    public func fetchUserLanguage() -> Single<String> {
        return dataService.fetchUserLanguage()
            .do(onSuccess: { identifier in
                self.userLanguage.value = identifier
            })
    }
}
