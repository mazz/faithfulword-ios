import Foundation
import RxSwift

protocol LanguageServicing {
    var userLanguage: Field<String> { get }
    func updateUserLanguage(languageIdentifier: String) -> Single<String>
}

public final class LanguageService: LanguageServicing {

    // MARK: Fields
    public var userLanguage: Field<String>

    // MARK: Dependencies
    private let dataService: UserDataServicing

    public init(dataService: UserDataServicing) {
        self.dataService = dataService
        userLanguage = Field("LanguageService init")
    }

    public func updateUserLanguage(languageIdentifier: String) -> Single<String> {
        return dataService.updateUserLanguage(identifier: languageIdentifier)
            .do(onSuccess: { identifier in
                self.userLanguage.value = identifier
            })
    }
}
