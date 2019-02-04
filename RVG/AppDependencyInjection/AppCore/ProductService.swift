import Foundation
import RxSwift

/// Various states of user's products and when they are discovered by the app
///
/// - noProductsRegistered: Upon retrieval of Products from a Passport users account, and there are no Products
/// - findingProducts: It is in the process of finding devices
/// - productsFound: There are Products on the users Passport account, and we have found atleast one
public enum ProductsFoundState {
    case noProductsRegistered
    case findingProducts
    case productsFound
}

/// Errors that may occur during ProductService tasks
///
/// - resourceLoadFailed: Loading and usage of a resource has failed.
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

    func fetchChapters(for bookUuid: String, offset: Int, limit: Int) -> Single<[Playable]>
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

    public func fetchChapters(for bookUuid: String, offset: Int, limit: Int) -> Single<[Playable]> {
        return dataService.chapters(for: bookUuid, offset: offset, limit: limit)
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

    //    public func addProduct(productName: String,
    //                           productId: String,
    //                           productType: String,
    //                           deviceId: String) -> Single<Void> {
    //        return dataService.addProduct(productName: productName,
    //                                      productId: productId,
    //                                      productType: productType)
    //            // Store the mapping of discovered device identifier to MAC address
    //            .flatMap { [unowned self] _ -> Single<Void> in
    //                self.storeProductIdentifier(deviceId: deviceId, guid: productId)
    //            }
    //    }

    //    public func availability(of identifier: String) -> Observable<UserProduct?> {
    //        return self.userProducts
    //            .asObservable()
    //            .map { userProducts -> UserProduct? in
    //                if let userProduct = userProducts.first(where: { userProduct -> Bool in
    //                    return userProduct.productId == identifier
    //                }) {
    //                    return userProduct
    //                }
    //                return nil
    //            }
    //    }

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


    //    public func updateSettings(_ settings: ProductSettings, for productId: String) -> Single<Void> {
    //        return dataService.updateSettings(settings, for: productId)
    //    }
    //
    //    public func suggestedNames(for productType: ProductType) -> Single<[String]> {
    //        return Single.create { single in
    //            let disposable = Disposables.create()
    //            guard let path = ModuleInfo.bundle.path(forResource: "SuggestedNames", ofType: "json"),
    //                let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
    //                let suggestedDeviceNames = try? JSONDecoder().decode(SuggestedDeviceNames.self, from: data) else {
    //                    single(.error(ProductServiceError.resourceLoadFailed))
    //                    return disposable
    //            }
    //            single(.success(suggestedDeviceNames.list(for: productType)))
    //            return disposable
    //        }
    //    }

    // MARK: Private helpers


    /// Store the map of product identifier to mac address in user default
    ///
    /// - Parameters:
    ///   - deviceId: identifier of discoveredDevice
    ///   - guid: guid of the discoveredDevice
    /// - Returns: Observable that emits if successfully stored
    //    private func storeProductIdentifier(deviceId: String, guid: String) -> Single<Void> {
    //        let userDefault = UserDefaults.standard
    //
    //        var dictionary = userDefault.object(forKey: Constants.productIdentifierDictionary) as? [String: String] ?? [:]
    //        dictionary[guid] = deviceId
    //        userDefault.set(dictionary, forKey: Constants.productIdentifierDictionary)
    //
    //        return Single.just(())
    //    }
}
