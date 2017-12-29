import RxSwift
import Moya
import L10n_swift

//import BoseMobileModels
//import BoseMobileData
//import BoseMobileUtilities

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

//public enum BMXDataServicingError: Error, LocalizedError {
//    case noBaseUrl(request: String)
//
//    public var errorDescription: String? {
//        switch self {
//        case .noBaseUrl(let request):
//            return "No base URL found for BMX \(request)"
//        }
//    }
//}

/// Provides BMX related data to the app
//public protocol BMXDataServicing {
//
//    // BMXMusicServiceProvider
//    var supportedMusicDescriptions: Observable<[MusicServiceDescription]> { get }
//    var musicServiceAvailabilities: Observable<[MusicServiceAvailabilities.Availability]> { get }
//
//    func fetchSupportedServices() -> Observable<[MusicServiceDescription]>
//    func fetchAvailableServices() -> Observable<[MusicServiceAvailabilities.Availability]>
//    func fetchLogin(for service: MusicServiceAvailabilities.Availability) -> Single<MusicServiceLoginPage>
//    func deleteAccount(_ account: MusicServiceAccount) -> Single<Void>
//
//    // BMXMusicService
//    func fetchCreds(for service: MusicService) -> Single<MusicServiceCreds>
//    func fetchNavigation(for service: MusicService, navigationLink: NavigationLink?) -> Single<NavigationSectionsContaining>
//}

/// Provides product related data to the app
public protocol ProductDataServicing {
    /// Permanent observable emitting product arrays
    var books: Observable<[Book]> { get }
    
    /// Fetches the latest products from the cloud.arrays
    ///
    /// - Returns: Permanent observable emitting product arrays
    func fetchAndObserveBooks() -> Observable<[Book]>
    
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
    
//    private let dataStore: DataStoring
//    private let passportNetworking: MoyaProvider<PassportAPI>!
//    private let bmxNetworking: MoyaProvider<BMXMusicServiceAPI>!
    private let kjvrvgNetworking: MoyaProvider<KJVRVGService>!
    
    // MARK: Fields
    
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
    
    // MARK: BMX
    
//    private var _supportedMusicDescriptions = Field<[MusicServiceDescription]>([])
//    private var _musicServiceAvailabilities = Field<[MusicServiceAvailabilities.Availability]>([])
    
    public init(
//        dataStore: DataStoring,
//                passportNetworking: MoyaProvider<PassportAPI>,
//                bmxNetworking: MoyaProvider<BMXMusicServiceAPI>,
                kjvrvgNetworking: MoyaProvider<KJVRVGService>) {
//        self.dataStore = dataStore
//        self.passportNetworking = passportNetworking
//        self.bmxNetworking = bmxNetworking
        self.kjvrvgNetworking = kjvrvgNetworking
        
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


//public enum BMXError: Error {
//    case failedResponse
//    case failedParse
//    case unauthorized
//}

//extension DataService: BMXDataServicing {
//    // BMXMusicServiceProvider
//
//    public var supportedMusicDescriptions: Observable<[MusicServiceDescription]> { return _supportedMusicDescriptions.asObservable() }
//    public var musicServiceAvailabilities: Observable<[MusicServiceAvailabilities.Availability]> { return _musicServiceAvailabilities.asObservable() }
//
//    public func fetchSupportedServices() -> Observable<[MusicServiceDescription]> {
//        return bmxNetworking.rx
//            .request(.services)
//            .parse(type: MusicServicesResponse.self)
//            .map { $0.bmxServices }
//            .do(onNext: { [unowned self] descriptions in
//                self._supportedMusicDescriptions.value = descriptions
//            })
//            .asObservable()
//            .flatMap { [unowned self] _ in self.supportedMusicDescriptions }
//    }
//
//    public func fetchAvailableServices() -> Observable<[MusicServiceAvailabilities.Availability]> {
//        return bmxNetworking.rx
//            .request(.servicesAvailability)
//            .parse(type: MusicServiceAvailabilities.self)
//            .do(onNext: { [unowned self] availabilities in
//                self._musicServiceAvailabilities.value = availabilities.availabilities
//            })
//            .asObservable()
//            .flatMap { [unowned self] _ in self.musicServiceAvailabilities }
//    }
//
//    public func fetchLogin(for service: MusicServiceAvailabilities.Availability) -> Single<MusicServiceLoginPage> {
//        return assertingSessionWithToken
//            .flatMap { [unowned self] session -> Single<Response> in
//                self.bmxNetworking.rx.request(.loginPage(login: service.loginPage,
//                                                         userToken: session.accessToken!,
//                                                         bosePersonId: session.bosePersonId))
//            }
//            .parse(type: MusicServiceLoginPage.self)
//    }
//
//    public func deleteAccount(_ account: MusicServiceAccount) -> Single<Void> {
//        return assertingSessionWithToken
//            .flatMap { [unowned self] session -> Single<Response> in
//                self.bmxNetworking.rx.request(.delete(accountId: account.accountId,
//                                                      userToken: session.accessToken!,
//                                                      bosePersonId: session.bosePersonId))
//            }
//            .filterSuccessfulStatusCodes()
//            .toVoid()
//    }
//
//    // BMXMusicService
//
//    public func fetchCreds(for service: MusicService) -> Single<MusicServiceCreds> {
//        guard let baseUrl = service.serviceDescription.baseUrl else {
//            return Single.error(BMXDataServicingError.noBaseUrl(
//                request: "fetchCreds - .token")
//            )
//        }
//        return bmxNetworking.rx
//            .request(
//                .token(
//                    refreshToken: service.account.tokens.refreshToken,
//                    baseUrl: baseUrl,
//                    link: service.serviceDescription.links.token?.href
//                )
//            )
//            .parse(type: MusicServiceCreds.self)
//    }
//
//    public func fetchNavigation(for service: MusicService, navigationLink: NavigationLink?) -> Single<NavigationSectionsContaining> {
//        guard let baseUrl = service.serviceDescription.baseUrl else {
//            return Single.error(BMXDataServicingError.noBaseUrl(
//                request: "fetchNavigation - .navigate")
//            )
//        }
//        var link = service.serviceDescription.links.navigate?.href
//        if let navigate = navigationLink {
//            link = navigate.href
//        }
//        return bmxNetworking.rx
//            .request(
//                .navigate(
//                    token: service.account.tokens.accessToken,
//                    baseUrl: baseUrl,
//                    link: link
//                )
//            )
//            .map { response -> NavigationSectionsContaining in
//                if response.statusCode == 401 {
//                    throw BMXError.unauthorized
//                }
//                guard let serializedJSONOptional = try? JSONSerialization.jsonObject(with: response.data),
//                    let responseDictionary = serializedJSONOptional as? [String: Any],
//                    let sectionsList = responseDictionary[NavigationKey.sectionsKey.rawValue] as? [Any]
//                    else {
//                        BoseLog.error("BMX malformed response, cannot convert to Dictionary.")
//                        if let bmxResponse = response.data.utf8String { BoseLog.error(bmxResponse) }
//                        throw BMXError.failedResponse
//                }
//
//                guard let container =
//                    NavigationSectionsContainer(
//                        sectionsList: sectionsList,
//                        source: service.serviceDescription.id.name,
//                        sourceAccount: service.account.name
//                    )
//                    else {
//                        BoseLog.error("BMX failed to parse response")
//                        if let bmxResponse = response.data.utf8String { BoseLog.error(bmxResponse) }
//                        throw BMXError.failedParse
//                }
//
//                return container
//        }
//    }
//}

extension DataService: ProductDataServicing {
    
    public var books: Observable<[Book]> {
        return _books.asObservable()
    }
    
    public func fetchAndObserveBooks() -> Observable<[Book]> {

        let moyaResponse = self.kjvrvgNetworking.rx.request(.books(languageId: L10n.shared.language))
//        let moyaResponse = self.kjvrvgNetworking.rx.request(.books(languageId: "el"))
        let bookResponse: Single<BookResponse> = moyaResponse.map { response -> BookResponse in
            try! response.map(BookResponse.self)
        }
        let books: Observable<[Book]> = bookResponse.flatMap { bookResponse -> Single<[Book]> in
            Single.just(bookResponse.result)
        }
        .do(onNext: { products in
            self._books.value = products
        })
        .asObservable()
        return books
//        .flatMap { [unowned self] _ in self.products }
        
//            .map { moyaResponse in try! moyaResponse.map(BookResponse.self) }
//            .flatMap({ bookResponse -> Single<[Book]> in
//                bookResponse.result
//            })
//            .asObservable()

        
//            .flatMap { bookResponse in bookResponse.result }
//            .do(onNext: { products in
//                self._books.value = products
//            })
//            .asObservable()
        
        
//            .parse(type: BookResponse.self)
//            .flatMap { bookResponse in bookResponse.result }
//            .do(onNext: { products in
//                self._products.value = products
//            })
//            .asObservable()
//            .flatMap { [unowned self] _ in self.products }

//            .flatMap { [unowned self] in self.productsWithSettings(products: $0) }
//            .flatMap { [unowned self] in self.replacePersistedProducts($0) }
            
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
