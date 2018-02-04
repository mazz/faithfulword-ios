import RxSwift
import Moya
import L10n_swift
import Alamofire

private enum DataServiceError: Error {
    case noSession
    case noAccessToken
}

// Provides account related data to the app
public protocol AccountDataServicing {

    /// Permanent observable providing session objects.
    var session: Observable<String?> { get }

    /// Permanent observable providing a list of MusicServiceAccounts.
    //    var musicServiceAccounts: Observable<[MusicServiceAccount]> { get }

    /// Downloads the user's session from Passport.
    ///
    /// - Parameters:
    ///   - user: The Gigya user object for which the session is required.
    ///   - idToken: The Gigya token obtained for the user.
    /// - Returns: Single with the session object.
    func fetchSession() -> Single<String>

    /// Delete's the user's session from disk.
    ///
    /// - Returns: Single indicating success or failure.
    //    @discardableResult func deleteSession() -> Single<Void>

    //    func fetchRemoteServiceMap(for user: GigyaUser) -> Single<RemoteServiceMap>

    /// Fetch the account object for a given GosePerson from Passport.
    ///
    /// - Returns: Single with the account info object.
    //    func fetchAccountInfo() -> Single<PassportAccountInfo>

    /// Fetches MusicServiceAccounts from Passport.
    ///
    /// - Returns: Either a permanent observable of MusicServiceAccounts or an erroring observable based on the success of the routine. Waits until the fetch routing completes before emitting anything.
    //    func fetchMusicServiceAccounts() -> Observable<[MusicServiceAccount]>
}

/// Provides product related data to the app
public protocol ProductDataServicing {
    /// Permanent observable emitting product arrays
    var books: Observable<[Book]> { get }
    //    var persistedBooks: Observable<[Book]> { get }

    /// Fetches the latest products from the cloud.arrays
    ///
    /// - Returns: Permanent observable emitting product arrays
    func chapters(for bookUuid: String) -> Single<[Playable]>

    func fetchAndObserveBooks() -> Observable<[Book]>

    func deletePersistedBooks() -> Single<Void>

    func categoryListing(for categoryType: CategoryListingType) -> Single<[Categorizable]>


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

    private var _session = Field<String?>(nil)
    //    private var assertingSession: Single<GoseSession> {
    //        guard let value = _session.value else {
    //            assertionFailure("No session. Must call this function after login so a session exists.")
    //            return Single.error(DataServiceError.noSession)
    //        }
    //
    //        return Single.just(value)
    //    }
    //    private var assertingSessionWithToken: Single<GoseSession> {
    //        return assertingSession
    //            .map { session -> GoseSession in
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
        loadInMemoryCache()
    }

    // MARK: Helpers

    private func loadInMemoryCache() {
        self.loadBooks()
            .subscribeAndDispose(by: bag)
    }
}

extension DataService: AccountDataServicing {
    public func fetchSession() -> Single<String> {
        return Single.just("a-fake-session")
            .flatMap { [unowned self] in
                self.dataStore.addUser(session: $0) }
            .do(onNext: { [unowned self] session in
                self._session.value = session
            })
    }

    //    public func fetchRemoteServiceMap(for user: GigyaUser) -> Single<RemoteServiceMap> {
    //        return galapagosNetworking.rx.request(.remoteServices(gigyaUserId: user.uid))
    //            .parse(type: RemoteServiceMap.self)
    //            .do(onNext: { map in
    //                GoseLog.debug("RemoteServiceMap: \(map)")
    //            })
    //    }

    public var session: Observable<String?> { return _session.asObservable() }
    //    public var musicServiceAccounts: Observable<[MusicServiceAccount]> { return _musicServiceAccounts.asObservable() }

    //    public func fetchSession(for user: GigyaUser, idToken: String) -> Single<GoseSession> {
    //        return passportNetworking.rx.request(.tokens(user: user, idToken: idToken))
    //            .parse(type: PassportAccountSession.self)
    //            .flatMap { [unowned self] in self.dataStore.addPerson(boseSession: $0) }
    //            .do(onNext: { [unowned self] session in
    //                self._session.value = session
    //            })
    //    }

    //    public func deleteSession() -> Single<Void> {
    //        self._session.value = nil
    //        return dataStore.deletePersistedUser()
    //    }

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

    // MARK: Helpers

}

extension DataService: ProductDataServicing {
    public func chapters(for bookUuid: String) -> Single<[Playable]> {
        switch self.networkStatus.value {
        case .notReachable:
            return dataStore.fetchChapters(for: bookUuid)
        case .reachable(_):
            let moyaResponse = self.kjvrvgNetworking.rx.request(.booksChapterMedia(bid: bookUuid, languageId: L10n.shared.language))
            let mediaChapterResponse: Single<MediaChapterResponse> = moyaResponse.map { response -> MediaChapterResponse in
                try! response.map(MediaChapterResponse.self)
            }
            let storedChapters: Single<[Playable]> = mediaChapterResponse.flatMap { [unowned self] mediaChapterResponse -> Single<[Playable]> in
                self.replacePersistedChapters(chapters: mediaChapterResponse.result, for: bookUuid)
            }
            return storedChapters
        case .unknown:
            return dataStore.fetchChapters(for: bookUuid)
        }
    }

    public var books: Observable<[Book]> {
        switch self.networkStatus.value {
        case .notReachable:
            print("DataService reachability.notReachable")
            return _books.asObservable()
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
        return self.kjvrvgNetworking.rx.request(.books(languageId: L10n.shared.language))
        //            .catchError { _ in Single.just(product) }
        .map { response -> BookResponse in try! response.map(BookResponse.self) }
            .flatMap { bookResponse -> Single<[Book]> in Single.just(bookResponse.result) }
            .flatMap { [unowned self] in self.replacePersistedBooks($0) }
            .do(onNext: { products in
                self._books.value = products
                //            self._persistedBooks.value = products
            })
            .asObservable()
    }

    public func deletePersistedBooks() -> Single<Void> {
        return self.dataStore.deleteAllBooks()
    }

    public func categoryListing(for categoryType: CategoryListingType) -> Single<[Categorizable]> {

        //        switch categoryType {
        //        case .gospel:

        return self.kjvrvgNetworking.rx.request(.gospels(languageId: L10n.shared.language))
            .map { response -> GospelResponse in
                try! response.map(GospelResponse.self)
            }.flatMap { gospelResponse -> Single<[Categorizable]> in
                gospelResponse.result
                print("gospelResponse.result: \(gospelResponse.result)")
                return Single.just(gospelResponse.result)
        }

        //                .map({ response -> [Gospel] in
        //                    try! response.map(GospelResponse.self)
        ////                    print(
        //                })
        //                .map { response -> GospelResponse in try! response.map(GospelResponse.self) }
        //                .flatMap({ gospelResponse -> Single<[Gospel]> in
        //
        //                })
        //                .flatMap { gospelResponse -> Single<[Gospel]> in

        //                    Single.just([Cate])

        //            }
        //            print(".gospel")
        //        case .music:
        //            print(".music")
        //            response = self.kjvrvgNetworking.rx.request(.music)
        //        case .churches:
        //            print(".churches")
        //            response = self.kjvrvgNetworking.rx.request(.churches)
        //        }
        //        return Single.just([])
    }

    // MARK: Private helpers

    private func replacePersistedBooks(_ books: [Book]) -> Single<[Book]> {
        // Likely the source of existing bug: login/logout/login with different user seeing old user's products.
        return dataStore.deleteAllBooks()
            .flatMap { [unowned self] in self.dataStore.addBooks(books: books) }
    }

    private func loadBooks() -> Observable<[Book]> {
        return dataStore.fetchBooks()
        //            .asObservable()
        .do(
            onNext: { [weak self] books in
                self?._books.value = books
            },
            onError: { [weak self] error in
                print("error: \(error.localizedDescription)")
                self?._books.value = []
            })
            .asObservable()
    }

    private func replacePersistedChapters(chapters: [Playable], for bookUuid: String) -> Single<[Playable]> {
        let deleted: Single<Void> = dataStore.deleteChapters(for: bookUuid)
        return deleted.flatMap { [unowned self] _ in self.dataStore.addChapters(chapters: chapters, for: bookUuid) }
    }

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
    //        return dataStore.deleteGosePerson()
    //            .flatMap { [unowned self] in self.assertingSession }
    //            .flatMap { [unowned self] in self.dataStore.addProducts(boseSession: $0, products: products) }
    //    }
    //
    //    private func loadProducts(with session: GoseSession) -> Single<[UserProduct]> {
    //        return dataStore.fetchAccountDevices(bosePersonId: session.bosePersonId)
    //            .do(
    //                onNext: { [weak self] products in
    //                    self?._products.value = products
    //                },
    //                onError: { [weak self] error in
    //                    GoseLog.error(error.localizedDescription)
    //                    self?._products.value = []
    //            })
    //    }
}
