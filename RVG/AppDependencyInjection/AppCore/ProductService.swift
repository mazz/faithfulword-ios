import Foundation
import RxSwift

public enum ProductsFoundState {
    case noProductsRegistered
    case findingProducts
    case productsFound
}

public enum ProductServiceError: Error {
    case resourceLoadFailed
}

public protocol ProductServicing {

    /// List of products registered to the user's Passport account
    var userBooks: Field<[Book]> { get }
    //    var userChapters: Field<[Playable]> { get }
    //    var persistedUserBooks: Field<[Book]> { get }

    func fetchBooks(stride: Int) -> Single<Void>

    func deleteBooks() -> Single<Void>

    func fetchChapters(for bookUuid: String, stride: Int) -> Single<[Playable]>
    func fetchMediaGospel(for categoryUuid: String) -> Single<[Playable]>
    func fetchMediaMusic(for categoryUuid: String) -> Single<[Playable]>
    func fetchBibleLanguages() -> Single<[LanguageIdentifier]>

    func fetchCategoryListing(for categoryType: CategoryListingType) -> Single<[Categorizable]>
}

public final class ProductService {

    public let userBooks: Field<[Book]>
    //    public var userChapters: Field<[Playable]>

    //    public let persistedUserBooks: Field<[Book]>

    // MARK: Dependencies & instantiation
    private let dataService: ProductDataServicing

    private var bag = DisposeBag()

    public init(dataService: ProductDataServicing) {
        self.dataService = dataService
        userBooks = Field(value: [], observable: dataService.books)
        //        userChapters = Field(value: [], observable: dataService.chapters)
        //        persistedUserBooks = Field(value: [], observable: dataService.persistedBooks)
    }
}

// MARK: <ProductServicing>
extension ProductService: ProductServicing {

    public func fetchChapters(for bookUuid: String, stride: Int) -> Single<[Playable]> {
        return dataService.chapters(for: bookUuid, stride: stride)
    }

    public func fetchMediaGospel(for categoryUuid: String) -> Single<[Playable]> {
        return dataService.mediaGospel(for: categoryUuid)
    }

    public func fetchMediaMusic(for categoryUuid: String) -> Single<[Playable]> {
        return dataService.mediaMusic(for: categoryUuid)
    }

    public func fetchBibleLanguages() -> Single<[LanguageIdentifier]> {
        return dataService.bibleLanguages()
    }

    public func fetchBooks(stride: Int) -> Single<Void> {
        return dataService.fetchAndObserveBooks(stride: stride).toVoid()
    }

    public func deleteBooks() -> Single<Void> {
        return dataService.deletePersistedBooks()
    }

    public func fetchCategoryListing(for categoryType: CategoryListingType) -> Single<[Categorizable]> {
        return dataService.categoryListing(for: categoryType)
    }
    //func fetchChapters(for bookUuid: String) -> Single<[Playable]>
}
