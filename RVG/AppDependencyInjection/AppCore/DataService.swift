import RxSwift
import Moya
import L10n_swift
import Alamofire

public enum DataServiceError: Error {
    case noSession
    case noAccessToken
    case decodeFailed
    case offsetOutofRange
}

public protocol UserDataServicing {
    var languageIdentifier: Observable<String> { get }
    func updateUserLanguage(identifier: String) -> Single<String>
    func fetchUserLanguage() -> Single<String>
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
    // keep state of last call to manage optimizations
//    var responseMap: [String: DownloadDataService] { get }
    //    var persistedBooks: Observable<[Book]> { get }

    /// Fetches the latest products from the cloud.arrays
    ///
    /// - Returns: Permanent observable emitting product arrays
    func chapters(for bookUuid: String) -> Single<[Playable]>
    func fetchAndObserveBooks(offset: Int, limit: Int) -> Observable<[Book]>
    func deletePersistedBooks() -> Single<Void>

    func mediaGospel(for categoryUuid: String) -> Single<[Playable]>
    func mediaMusic(for categoryUuid: String) -> Single<[Playable]>
    func bibleLanguages() -> Single<[LanguageIdentifier]>

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

    // MARK: UserDataServicing
    private var _languageIdentifier = Field<String>("test init identifier")
    private var _session = Field<String?>(nil)
    // MARK: ProductDataServicing
    private var _books = Field<[Book]>([])
    private var _responseMap: [String: Response] = [:]
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

    private func loadInMemoryCache() {
        self.loadBooks()
            .subscribeAndDispose(by: bag)
    }
}

extension DataService: UserDataServicing {

    public var languageIdentifier: Observable<String> { return _languageIdentifier.asObservable() }

    public func updateUserLanguage(identifier: String) -> Single<String> {
//        let updated: Single<String> =
        return self.dataStore.updateUserLanguage(identifier: identifier)
//        return Single.just(identifier)

//            return updated.map { [unowned self] identifier in
//                self._languageIdentifier.value = identifier }
//            .toVoid()
    }

    public func fetchUserLanguage() -> Single<String> {
        return self.dataStore.fetchUserLanguage()
    }
}


extension DataService: AccountDataServicing {
    public func fetchSession() -> Single<String> {
        return Single.just("a-fake-session")
            .flatMap { [unowned self] in
                self.dataStore.addUser(session: $0) }
            .do(onSuccess: { [unowned self] session in
                self._session.value = session
            })
    }

    public var session: Observable<String?> { return _session.asObservable() }

    // MARK: Helpers

}

extension DataService: ProductDataServicing {
    public func chapters(for bookUuid: String) -> Single<[Playable]> {
        switch self.networkStatus.value {
        case .notReachable:
            return dataStore.fetchChapters(for: bookUuid)
        case .reachable(_):
            let moyaResponse = self.kjvrvgNetworking.rx.request(.booksChapterMedia(uuid: bookUuid, languageId: L10n.shared.language))
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

    public func fetchAndObserveBooks(offset: Int, limit: Int) -> Observable<[Book]> {
        let request: KJVRVGService = .books(languageId: L10n.shared.language, offset: offset, limit: limit)
        let requestKey: String = String(describing: request).components(separatedBy: " ")[0]
        print("self._responseMap: \(self._responseMap)")
        
        if let cachedResponse: Response = self._responseMap[requestKey] {
            do {
                let bookResponse: BookResponse = try cachedResponse.map(BookResponse.self)
                let totalEntries: Int = bookResponse.totalEntries
                if offset >= totalEntries {
                    print(DataServiceError.offsetOutofRange)
                    return Single.error(DataServiceError.offsetOutofRange).asObservable()
                }
            } catch {
                print(DataServiceError.decodeFailed)
            }
        }
        
        switch self.networkStatus.value {
        case .reachable(_):
            return self.kjvrvgNetworking.rx.request(request)
                //            .catchError { _ in Single.just(product) }
                .map { [unowned self] response -> BookResponse in
                    do {
                        // cache response for the next call
                        self._responseMap[requestKey] = response
                        return try response.map(BookResponse.self)
                    } catch {
                        throw DataServiceError.decodeFailed
                    }
                }
                .flatMap { bookResponse -> Single<[Book]> in Single.just(bookResponse.result) }
                .flatMap { [unowned self] in self.appendPersistedBooks($0) }
                .do(onSuccess: { [unowned self] products in
                    self._books.value = products
                    //            self._persistedBooks.value = products
                })
                .asObservable()
        case .notReachable:
            return dataStore.fetchBooks().asObservable()
        case .unknown:
            return dataStore.fetchBooks().asObservable()
        }
//            .flatMap { [unowned self] in self.appendPersistedBooks($0) }
//            .map({ books in
//                return self.dataStore.fetchBooks()
//            })
//            .map({ books in
//                return books
//            })
//            .do(onSuccess: { [unowned self] products in
//                self._books.value = self.dataStore.fetchBooks()
//                //            self._persistedBooks.value = products
//            })
//            .asObservable()
    }

    public func deletePersistedBooks() -> Single<Void> {
        return self.dataStore.deleteAllBooks()
    }

    public func mediaGospel(for categoryUuid: String) -> Single<[Playable]> {
        switch self.networkStatus.value {
        case .notReachable:

            return dataStore.fetchMediaGospel(for: categoryUuid)
        case .reachable(_):
            let moyaResponse = self.kjvrvgNetworking.rx.request(.gospelsMedia(uuid: categoryUuid)) //(.booksChapterMedia(uuid: categoryUuid, languageId: L10n.shared.language))
            let mediaGospelResponse: Single<MediaGospelResponse> = moyaResponse.map { response -> MediaGospelResponse in
                try! response.map(MediaGospelResponse.self)
            }
            let storedMediaGospel: Single<[Playable]> = mediaGospelResponse.flatMap { [unowned self] mediaGospelResponse -> Single<[Playable]> in
                self.replacePersistedMediaGospel(mediaGospel: mediaGospelResponse.result, for: categoryUuid)
            }
            return storedMediaGospel
        case .unknown:
            return dataStore.fetchMediaGospel(for: categoryUuid)
        }
    }

    public func mediaMusic(for categoryUuid: String) -> Single<[Playable]> {
        switch self.networkStatus.value {
        case .notReachable:
            return dataStore.fetchMediaMusic(for: categoryUuid)
        case .reachable(_):
            let moyaResponse = self.kjvrvgNetworking.rx.request(.musicMedia(uuid: categoryUuid)) //(.booksChapterMedia(uuid: categoryUuid, languageId: L10n.shared.language))
            let mediaMusicResponse: Single<MediaMusicResponse> = moyaResponse.map { response -> MediaMusicResponse in
                try! response.map(MediaMusicResponse.self)
            }
            let storedMediaMusic: Single<[Playable]> = mediaMusicResponse.flatMap { [unowned self] mediaMusicResponse -> Single<[Playable]> in
                //                self.replacePersistedMediaGospel(mediaGospel: mediaGospelResponse.result, for: categoryUuid)
                self.replacePersistedMediaMusic(mediaMusic: mediaMusicResponse.result, for: categoryUuid)
            }
            return storedMediaMusic
        case .unknown:
            return dataStore.fetchMediaMusic(for: categoryUuid)
        }
    }

    public func bibleLanguages() -> Single<[LanguageIdentifier]> {
        switch self.networkStatus.value {
        case .unknown:
            return dataStore.fetchBibleLanguages()
        case .notReachable:
            return dataStore.fetchBibleLanguages()
        case .reachable(_):
            //        var categoryListing: Single<[LanguageIdentifier]> = Single.just([])
            return self.kjvrvgNetworking.rx.request(.languagesSupported)
                .map { response -> LanguagesSupportedResponse in
                    try! response.map(LanguagesSupportedResponse.self)
                }.flatMap { languagesSupportedResponse -> Single<[LanguageIdentifier]> in
                    print("languagesSupportedResponse.result: \(languagesSupportedResponse.result)")
                    return Single.just(languagesSupportedResponse.result)
                }
                .flatMap { [unowned self] in self.replacePersistedBibleLanguages(bibleLanguages: $0) }
        }
    }

    public func categoryListing(for categoryType: CategoryListingType) -> Single<[Categorizable]> {
        var categoryListing: Single<[Categorizable]> = Single.just([])

        switch categoryType {
        case .gospel:
            switch self.networkStatus.value {
            case .unknown:
                categoryListing = dataStore.fetchCategoryList(for: categoryType)
            case .notReachable:
                categoryListing = dataStore.fetchCategoryList(for: categoryType)
            case .reachable(_):
                print("reachable")
                categoryListing = self.kjvrvgNetworking.rx.request(.gospels(languageId: L10n.shared.language))
                    .map { response -> GospelResponse in
                        try! response.map(GospelResponse.self)
                    }.flatMap { gospelResponse -> Single<[Categorizable]> in
                        print("gospelResponse.result: \(gospelResponse.result)")
                        return Single.just(gospelResponse.result)
                    }
                    .flatMap { [unowned self] in self.replacePersistedCategoryList(categoryList: $0, for: categoryType) }
            }
        case .music:
            print(".music")
            switch self.networkStatus.value {
            case .unknown:
                categoryListing = dataStore.fetchCategoryList(for: categoryType)
            case .notReachable:
                categoryListing = dataStore.fetchCategoryList(for: categoryType)
            case .reachable(_):
                print("reachable")
                categoryListing = self.kjvrvgNetworking.rx.request(.music(languageId: L10n.shared.language))
                    .map { response -> MusicResponse in
                        try! response.map(MusicResponse.self)
                    }.flatMap { musicResponse -> Single<[Categorizable]> in
                        print("musicResponse.result: \(musicResponse.result)")
                        return Single.just(musicResponse.result)
                    }
                    .flatMap { [unowned self] in self.replacePersistedCategoryList(categoryList: $0, for: categoryType) }
            }
        case .churches:
            print(".churches")
        }
        return categoryListing
    }

    // MARK: Private helpers

    private func replacePersistedBooks(_ books: [Book]) -> Single<[Book]> {
        // Likely the source of existing bug: login/logout/login with different user seeing old user's products.
        return dataStore.deleteAllBooks()
            .flatMap { [unowned self] in self.dataStore.addBooks(books: books) }
    }
    
    private func appendPersistedBooks(_ books: [Book]) -> Single<[Book]> {
        // Likely the source of existing bug: login/logout/login with different user seeing old user's products.
        
        return self.dataStore.addBooks(books: books)
//            .do(onSuccess: { [unowned self] books in
//                return self.dataStore.fetchBooks()
//            })
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

    private func replacePersistedMediaGospel(mediaGospel: [Playable], for categoryUuid: String) -> Single<[Playable]> {
        let deleted: Single<Void> = dataStore.deleteMediaGospel(for: categoryUuid)
        return deleted.flatMap { [unowned self] _ in self.dataStore.addMediaGospel(mediaGospel: mediaGospel, for: categoryUuid) }
    }

    private func replacePersistedMediaMusic(mediaMusic: [Playable], for categoryUuid: String) -> Single<[Playable]> {
        let deleted: Single<Void> = dataStore.deleteMediaMusic(for: categoryUuid)
        return deleted.flatMap { [unowned self] _ in self.dataStore.addMediaMusic(mediaMusic: mediaMusic, for: categoryUuid) }
    }

    private func replacePersistedBibleLanguages(bibleLanguages: [LanguageIdentifier]) -> Single<[LanguageIdentifier]> {
        return dataStore.deleteBibleLanguages()
            .flatMap { [unowned self] _ in
                self.dataStore.addBibleLanguages(bibleLanguages: bibleLanguages)
        }
    }

    private func replacePersistedCategoryList(categoryList: [Categorizable],
                                              for categoryListType: CategoryListingType) -> Single<[Categorizable]> {
        let deleted: Single<Void> = dataStore.deleteCategoryList(for: categoryListType)
        return deleted.flatMap { [unowned self] _ in self.dataStore.addCategory(
            categoryList: categoryList,
            for: categoryListType) }
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
}
