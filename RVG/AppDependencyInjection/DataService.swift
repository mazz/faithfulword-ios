import RxSwift
import Moya
import L10n_swift
import Alamofire

//private enum DataServiceError: Error {
//    case noSession
//    case noAccessToken
//}

/// Provides account related data to the app
//public protocol AccountDataServicing {
//
//    /// Permanent observable providing session objects.
//    var session: Observable<BoseSession?> { get }
//
//    /// Permanent observable providing a list of MusicServiceAccounts.
//    var musicServiceAccounts: Observable<[MusicServiceAccount]> { get }
//
//    /// Downloads the user's session from Passport.
//    ///
//    /// - Parameters:
//    ///   - user: The Gigya user object for which the session is required.
//    ///   - idToken: The Gigya token obtained for the user.
//    /// - Returns: Single with the session object.
//    func fetchSession(for user: GigyaUser, idToken: String) -> Single<BoseSession>
//
//    /// Delete's the user's session from disk.
//    ///
//    /// - Returns: Single indicating success or failure.
//    @discardableResult func deleteSession() -> Single<Void>
//
//    func fetchRemoteServiceMap(for user: GigyaUser) -> Single<RemoteServiceMap>
//
//    /// Fetch the account object for a given BosePerson from Passport.
//    ///
//    /// - Returns: Single with the account info object.
//    func fetchAccountInfo() -> Single<PassportAccountInfo>
//
//    /// Fetches MusicServiceAccounts from Passport.
//    ///
//    /// - Returns: Either a permanent observable of MusicServiceAccounts or an erroring observable based on the success of the routine. Waits until the fetch routing completes before emitting anything.
//    func fetchMusicServiceAccounts() -> Observable<[MusicServiceAccount]>
//}

/// Provides product related data to the app
public protocol ProductDataServicing {
    /// Permanent observable emitting product arrays
    var books: Observable<[Book]> { get }
//    var persistedBooks: Observable<[Book]> { get }

    /// Fetches the latest products from the cloud.arrays
    ///
    /// - Returns: Permanent observable emitting product arrays
    func fetchAndObserveBooks() -> Observable<[Book]>
    
    func deletePersistedBooks() -> Single<Void>
    
    /// Updates the settings of a user's product.
    ///
    /// - Parameters:
    ///   - settings: The settings to change for the particular product.
    ///   - productId: The ID of the product to update.
    /// - Returns: Single which emits when the product was succesfully updated.
//    func updateSettings(_ settings: ProductSettings, for productId: String) -> Single<Void>
    
    /// Associates with a product with an account.
    ///
    /// - Parameters:
    ///   - productName: Name of the product
    ///   - productId: ID of the product
    ///   - productType: Type of the product
    /// - Returns: Success/Failure single
//    func addProduct(productName: String, productId: String, productType: String) -> Single<Void>
}

public final class DataService {
    
    // MARK: Dependencies
    
    private let dataStore: DataStoring
    private let kjvrvgNetworking: MoyaProvider<KJVRVGService>!
    private let reachability: RxReachable!

    // MARK: Fields
    
    
    private var networkStatus = Field<Alamofire.NetworkReachabilityManager.NetworkReachabilityStatus>(.unknown)
    private let bag = DisposeBag()
    
    // MARK: Session
    
//    private var _session = Field<BoseSession?>(nil)
//    private var assertingSession: Single<BoseSession> {
//        guard let value = _session.value else {
//            assertionFailure("No session. Must call this function after login so a session exists.")
//            return Single.error(DataServiceError.noSession)
//        }
//
//        return Single.just(value)
//    }
//    private var assertingSessionWithToken: Single<BoseSession> {
//        return assertingSession
//            .map { session -> BoseSession in
//                if session.accessToken == nil {
//                    assertionFailure("No user access token. Passport must have not provided one.")
//                    throw DataServiceError.noAccessToken
//                }
//
//                return session
//        }
//    }
    
    // MARK: Account
    
//    private var _musicServiceAccounts = Field<[MusicServiceAccount]>([])
    
    // MARK: Product
    
    private var _books = Field<[Book]>([])
    private var _persistedBooks = Field<[Book]>([])
    
    public init(
        dataStore: DataStoring,
        kjvrvgNetworking: MoyaProvider<KJVRVGService>,
        reachability: RxReachable) {
        self.dataStore = dataStore
        self.kjvrvgNetworking = kjvrvgNetworking
        self.reachability = reachability
        
        reactToReachability()
        //        loadInMemoryCache()
    }
    
    // MARK: Helpers
    
//    private func loadInMemoryCache() {
//        loadSession()
//            .asObservable()
//            .filterNils()
//            .flatMap { [unowned self] in self.loadProducts(with: $0) }
//            .subscribeAndDispose(by: bag)
//    }
}

//extension DataService: AccountDataServicing {
//    public func fetchRemoteServiceMap(for user: GigyaUser) -> Single<RemoteServiceMap> {
//        return galapagosNetworking.rx.request(.remoteServices(gigyaUserId: user.uid))
//            .parse(type: RemoteServiceMap.self)
//            .do(onNext: { map in
//                BoseLog.debug("RemoteServiceMap: \(map)")
//            })
//    }
//
//    public var session: Observable<BoseSession?> { return _session.asObservable() }
//    public var musicServiceAccounts: Observable<[MusicServiceAccount]> { return _musicServiceAccounts.asObservable() }
//
//    public func fetchSession(for user: GigyaUser, idToken: String) -> Single<BoseSession> {
//        return passportNetworking.rx.request(.tokens(user: user, idToken: idToken))
//            .parse(type: PassportAccountSession.self)
//            .flatMap { [unowned self] in self.dataStore.addPerson(boseSession: $0) }
//            .do(onNext: { [unowned self] session in
//                self._session.value = session
//            })
//    }
//
//    public func deleteSession() -> Single<Void> {
//        self._session.value = nil
//        return dataStore.deleteBosePerson()
//    }
//
//    public func fetchAccountInfo() -> Single<PassportAccountInfo> {
//        return assertingSession
//            .flatMap { [unowned self] in self.passportNetworking.rx.request(.accountInfo(bosePersonId: $0.bosePersonId)) }
//            .parse(type: PassportAccountInfo.self)
//    }
//
//    public func fetchMusicServiceAccounts() -> Observable<[MusicServiceAccount]> {
//        return assertingSession
//            .flatMap { [unowned self] in self.passportNetworking.rx.request(.accounts(bosePersonId: $0.bosePersonId)) }
//            .map([MusicServiceAccount].self)
//            .do(onNext: { [unowned self] accounts in
//                self._musicServiceAccounts.value = accounts
//            })
//            .asObservable()
//            .flatMap { [unowned self] _ in self.musicServiceAccounts }
//    }
//
//    // MARK: Helpers
//
//    private func loadSession() -> Single<BoseSession?> {
//        return dataStore.latestCachedUser(boseSessionFactory: PassportAccountSession.init)
//            .do(
//                onNext: { [unowned self] session in
//                    self._session.value = session
//                },
//                onError: { [unowned self] error in
//                    BoseLog.error(error.localizedDescription)
//                    self._session.value = nil
//            })
//    }
//}



extension DataService: ProductDataServicing {
    
    public var books: Observable<[Book]> {
        switch self.networkStatus.value {
            case .notReachable:
                print("DataService reachability.notReachable")
                return _persistedBooks.asObservable()
            case .reachable(_):
                print("DataService reachability.reachable")
                return _books.asObservable()
            case .unknown:
                print("DataService reachability.unknown")
                return _books.asObservable()
        }
    }

//    public var persistedBooks: Observable<[Book]> {
//        return _persistedBooks.asObservable()
//    }

    public func fetchAndObserveBooks() -> Observable<[Book]> {
        let moyaResponse = self.kjvrvgNetworking.rx.request(.books(languageId: L10n.shared.language))
        let bookResponse: Single<BookResponse> = moyaResponse.map { response -> BookResponse in
            try! response.map(BookResponse.self)
        }
        let books: Observable<[Book]> = bookResponse.flatMap { bookResponse -> Single<[Book]> in
            Single.just(bookResponse.result)
        }
        .do(onNext: { products in
            self._books.value = products
//            self._persistedBooks.value = products
            self.dataStore.addBooks(books: products)
                .subscribe(onSuccess: { persisted in
                    self._persistedBooks.value = persisted
                }, onError: { error in
                    print("something bad happened: \(error)")
                }).disposed(by: self.bag)
        })
        .asObservable()
        return books
    }
    
    public func deletePersistedBooks() -> Single<Void> {
        return self.dataStore.deleteAllBooks()
    }
    
    // MARK: Private helpers
    
    private func reactToReachability() {
        reachability.startListening().asObservable()
            .subscribe(onNext: { networkStatus in
                self.networkStatus.value = networkStatus
                if networkStatus == .notReachable {
                    print("DataService reachability.notReachable")
                } else if networkStatus == .reachable(.ethernetOrWiFi) {
                    print("DataService reachability.reachable")
                }
            }).disposed(by: bag)
    }

//    public func updateSettings(_ settings: ProductSettings, for productId: String) -> Single<Void> {
//        return passportNetworking.rx
//            .request(.updateProductSettings(productId: productId, settings: settings))
//            .checkStatusCode()
//            .toVoid()
//            .asObservable()
//            .flatMap { [unowned self] in self.fetchAndObserveProducts() }
//            .take(1).asSingle()
//            .toVoid()
//    }
    
//    public func addProduct(productName: String, productId: String, productType: String) -> Single<Void> {
//        return assertingSession
//            .flatMap { [unowned self] session in
//                self.passportNetworking.rx.request(.addProduct(
//                    bosePersonId: session.bosePersonId,
//                    productId: productId,
//                    productType: productType
//                    ))
//            }
//            .checkStatusCode()
//            .toVoid()
//            .asObservable()
//            .flatMap { [unowned self] in self.fetchAndObserveProducts() }
//            .take(1).asSingle()
//            .toVoid()
//    }
    
    
    // MARK: Helpers
    
    // TODO CASTLE-4433 SR/SG - Can delete once products endpoint response includes Settings object
//    private func productsWithSettings(products: [UserProduct]) -> Single<[UserProduct]> {
//        // When products is empty, the single would error due to no element
//        if products.isEmpty { return Single.just(products) }
//
//        let newProducts = products.map { [unowned self] product -> Observable<UserProduct> in
//            return self.fetchSettings(for: product.productId)
//                .map {
//                    UserProduct(
//                        productId: product.productId,
//                        productType: product.productType,
//                        persons: product.persons,
//                        settings: $0
//                    )
//                }
//                .catchError { _ in Single.just(product) }
//                .asObservable()
//        }
//
//        return Observable.combineLatest(newProducts).take(1).asSingle()
//    }
//
//    private func fetchSettings(for productId: String) -> Single<ProductSettings> {
//        return passportNetworking.rx.request(.getProductSettings(productId: productId))
//            .parse(type: ProductSettings.self)
//    }
//
//    private func replacePersistedProducts(_ products: [UserProduct]) -> Single<[UserProduct]> {
//        // Likely the source of existing bug: login/logout/login with different user seeing old user's products.
//        return dataStore.deleteBosePerson()
//            .flatMap { [unowned self] in self.assertingSession }
//            .flatMap { [unowned self] in self.dataStore.addProducts(boseSession: $0, products: products) }
//    }
//
//    private func loadProducts(with session: BoseSession) -> Single<[UserProduct]> {
//        return dataStore.fetchAccountDevices(bosePersonId: session.bosePersonId)
//            .do(
//                onNext: { [weak self] products in
//                    self?._products.value = products
//                },
//                onError: { [weak self] error in
//                    BoseLog.error(error.localizedDescription)
//                    self?._products.value = []
//            })
//    }
}
