import Foundation
import RxSwift
//import BoseMobileModels
//import BoseMobileCommunication
//import BoseMobileData
//import BoseMobileUtilities

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

/// Combines product information from the cloud and the local data store.
/// The cloud is considered the source of truth.
/// The local data store is used for speed and when the cloud is not accessible.
public protocol ProductServicing {
    
    /// List of products registered to the user's Passport account
    var userBooks: Field<[Book]> { get }
//    var persistedUserBooks: Field<[Book]> { get }

    
    /// Adds a device to a user's account.
    ///
    /// - Parameters:
    ///   - productName: User selected name of the product
    ///   - productId: GUID of the device to add to the account
    ///   - productType: The product type
    /// - Returns: Observable emits PassportAddProductResponse when product is successfully added.
//    func addProduct(productName: String,
//                    productId: String,
//                    productType: String,
//                    deviceId: String) -> Single<Void>
    
    /// When a Product is available by ID, it will be returned, when not
    ///  in the users passport account, it will be nil
    /// - Parameter identifier: the Product ID of the UserProduct
    /// - Returns: the UserProduct, nil when not added to account
//    func availability(of identifier: String) -> Observable<UserProduct?>
    
    /// Updates the products associated with the bose user account
    ///
    /// - Returns: Returns Success or Error
    func fetchBooks() -> Single<Void>
    
    func deleteBooks() -> Single<Void>
    
    /// Updates the attributes of a user's product.
    ///
    /// - Parameters:
    ///   - settings: The settings to update on the product.
    ///   - productId: The ID of the product to update.
    /// - Returns: Single which emits when the product was succesfully updated.
//    func updateSettings(_ settings: ProductSettings, for productId: String) -> Single<Void>
    
    /// Gets the list of suggested names for a product type and current locale
    ///
    /// - Parameter productType: The type of product for contextual name suggestions
//    func suggestedNames(for productType: ProductType) -> Single<[String]>
    
}

public final class ProductService {
    public let userBooks: Field<[Book]>
//    public let persistedUserBooks: Field<[Book]>

    // MARK: Dependencies & instantiation
    private let dataService: ProductDataServicing

    private var bag = DisposeBag()
    
    public init(dataService: ProductDataServicing) {
        self.dataService = dataService
        userBooks = Field(value: [], observable: dataService.books)
//        persistedUserBooks = Field(value: [], observable: dataService.persistedBooks)
    }
}

// MARK: <ProductServicing>
extension ProductService: ProductServicing {
    
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

    public func fetchBooks() -> Single<Void> {
        return dataService.fetchAndObserveBooks().take(1).asSingle().toVoid()
    }
    
    public func deleteBooks() -> Single<Void> {
        return dataService.deletePersistedBooks()
    }
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
