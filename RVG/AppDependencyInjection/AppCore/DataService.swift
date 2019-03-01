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

    func fetchSession() -> Single<String>

}

/// Provides product related data to the app
public protocol ProductDataServicing {
    var books: Observable<[Book]> { get }

    func chapters(for bookUuid: String, stride: Int) -> Single<[Playable]>
    func fetchAndObserveBooks(stride: Int) -> Single<[Book]>
    func deletePersistedBooks() -> Single<Void>

    func mediaGospel(for categoryUuid: String, stride: Int) -> Single<[Playable]>
    func mediaMusic(for categoryUuid: String, stride: Int) -> Single<[Playable]>
    func bibleLanguages(stride: Int) -> Single<[LanguageIdentifier]>

    func categoryListing(for categoryType: CategoryListingType, stride: Int) -> Single<[Categorizable]>
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
    private var _categories = Field<[String: [Categorizable]]>([:])
    private var _media = Field<[String: [Playable]]>([:])

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
        loadInMemoryCache()
    }

    // MARK: Helpers

    private func loadInMemoryCache() {
        self.loadBooks()
            .subscribeAndDispose(by: bag)

        self.loadCategory(for: .music)
            .do(onNext: { uuid in
                self.dataStore.fetchMediaMusic(for: uuid)
                    .subscribe(onSuccess: { playableArray in
                        var mediaMap: [String: [Playable]] = self._media.value
                        mediaMap[uuid] = playableArray
                        self._media.value = mediaMap
                })
            })
            .subscribeAndDispose(by: bag)

        self.loadCategory(for: .gospel)
            .do(onNext: { uuid in
                self.dataStore.fetchMediaGospel(for: uuid)
                    .subscribe(onSuccess: { playableArray in
                        var mediaMap: [String: [Playable]] = self._media.value
                        mediaMap[uuid] = playableArray
                        self._media.value = mediaMap
                    })
            })
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

enum FetchState {
    case hasFetched
    case hasNotFetched
}

extension DataService: ProductDataServicing {
    public var books: Observable<[Book]> {
        switch self.networkStatus.value {
        case .notReachable:
            DDLogDebug("DataService reachability.notReachable")
            return _books.asObservable()
        case .reachable(_):
            DDLogDebug("DataService reachability.reachable")
            return _books.asObservable()
        case .unknown:
            DDLogDebug("DataService reachability.unknown")
            return _books.asObservable()
        }
    }

    
    
    public func chapters(for bookUuid: String, stride: Int) -> Single<[Playable]> {
        
        var mediaChapterResponse: MediaChapterResponse!
        var previousOffset = 0
        
        if let cachedResponse: Response = self._responseMap[bookUuid] {
            do {
                mediaChapterResponse = try cachedResponse.map(MediaChapterResponse.self)
                let totalEntries: Int = mediaChapterResponse.totalEntries
                let cachedPageNumber: Int = mediaChapterResponse.pageNumber
                let cachedPageSize: Int = mediaChapterResponse.pageSize
                
                let loadedSoFar: Int = cachedPageNumber * cachedPageSize
                previousOffset = cachedPageNumber
                
                // assume we've loaded at least once, so return the local db instead
                if loadedSoFar == stride {
                    return self.dataStore.fetchChapters(for: bookUuid)
                }
                else if loadedSoFar >= totalEntries {
                    DDLogDebug("DataServiceError.offsetOutofRange: \(DataServiceError.offsetOutofRange)")
                    return Single.error(DataServiceError.offsetOutofRange)
                }
            } catch {
                DDLogDebug("DataServiceError.decodeFailed: \(DataServiceError.decodeFailed)")
            }
        }
        
//        DDLogDebug("chapters offset \(offset) limit \(limit)")
        switch self.networkStatus.value {
        case .notReachable:
            return dataStore.fetchChapters(for: bookUuid)
        case .reachable(_):
//            let request: KJVRVGService = .books(languageId: L10n.shared.language, offset: offset, limit: limit)
//            let requestKey: String = String(describing: request).components(separatedBy: " ")[0]
//            DDLogDebug("self._responseMap: \(self._responseMap)")

            let moyaResponse = self.kjvrvgNetworking.rx.request(.booksChapterMedia(uuid: bookUuid, languageId: L10n.shared.language, offset: previousOffset + 1, limit: stride))
            let mediaChapterResponse: Single<MediaChapterResponse> = moyaResponse.map { response -> MediaChapterResponse in
                do {
                    self._responseMap[bookUuid] = response
                    return try response.map(MediaChapterResponse.self)
                } catch {
                    throw DataServiceError.decodeFailed
                }
            }
            let storedChapters: Single<[Playable]> = mediaChapterResponse.flatMap { [unowned self] mediaChapterResponse -> Single<[Playable]> in
                DDLogDebug("mediaChapterResponse.result: \(mediaChapterResponse.result)")
                return self.appendPersistedChapters(chapters: mediaChapterResponse.result, for: bookUuid)
            }
            return storedChapters
        case .unknown:
            return dataStore.fetchChapters(for: bookUuid)
        }
    }

    public func fetchAndObserveBooks(stride: Int) -> Single<[Book]> {
        var bookResponse: BookResponse!
        var previousOffset = 0
        var totalEntries = -1
        var loadedSoFar = -1
        var fetchState: FetchState = .hasNotFetched
        
//        let books: [Book] = self._books.value
//        DDLogDebug("books.count: \(books.count)")

        if let cachedResponse: Response = self._responseMap["booksResponse"] {
            do {
                fetchState = .hasFetched
                
                bookResponse = try cachedResponse.map(BookResponse.self)
                totalEntries = bookResponse.totalEntries
                let cachedPageNumber: Int = bookResponse.pageNumber
                let cachedPageSize: Int = bookResponse.pageSize
                
                loadedSoFar = cachedPageNumber * cachedPageSize
                previousOffset = cachedPageNumber
                
                if loadedSoFar >= totalEntries {
                    DDLogDebug("DataServiceError.offsetOutofRange: \(DataServiceError.offsetOutofRange)")
                    return Single.error(DataServiceError.offsetOutofRange)
                }
            } catch {
                DDLogDebug("DataServiceError.decodeFailed: \(DataServiceError.decodeFailed)")
            }
        }
//        else {
//            // we are making the first call to fetch books
//            request = .books(languageId: L10n.shared.language, offset: 1, limit: stride)
//        }

        /// if we got to this point we know there are more items to be fetched
        switch self.networkStatus.value {
        case .reachable(_):
            
            if loadedSoFar < totalEntries || fetchState == .hasNotFetched {
                // bookResponse should not be nil because otherwise DataServiceError.decodeFailed would have happened
                return self.kjvrvgNetworking.rx.request(.books(languageId: L10n.shared.language, offset: previousOffset + 1, limit: stride))
                    //            .catchError { _ in Single.just(product) }
                    .map { [unowned self] response -> BookResponse in
                        do {
                            // cache response for the next call
                            self._responseMap["booksResponse"] = response
                            return try response.map(BookResponse.self)
                        } catch {
                            throw DataServiceError.decodeFailed
                        }
                    }
                    .flatMap { bookResponse -> Single<[Book]> in
                        return Single.just(bookResponse.result)
                    }
                    .flatMap { [unowned self] in
                        self.appendPersistedBooks($0)
                    }
                    .do(onSuccess: { [unowned self] products in
                        self._books.value = products
                        //            self._persistedBooks.value = products
                    })
            } else {
                return Single.just(self._books.value) //dataStore.fetchBooks()
            }

//                .asObservable()
        case .notReachable:
            return Single.just(self._books.value) //dataStore.fetchBooks()
        case .unknown:
            return Single.just(self._books.value) //dataStore.fetchBooks()
        }
    }

    public func mediaGospel(for categoryUuid: String, stride: Int) -> Single<[Playable]> {
        var mediaGospelResponse: MediaGospelResponse!
        var previousOffset = 0
        var totalEntries = -1
        var loadedSoFar = -1
        var fetchState: FetchState = .hasNotFetched
        
        if let cachedResponse: Response = self._responseMap[categoryUuid] {
            do {
                fetchState = .hasFetched

                mediaGospelResponse = try cachedResponse.map(MediaGospelResponse.self)
                totalEntries = mediaGospelResponse.totalEntries
                let cachedPageNumber: Int = mediaGospelResponse.pageNumber
                let cachedPageSize: Int = mediaGospelResponse.pageSize
                
                loadedSoFar = cachedPageNumber * cachedPageSize
                previousOffset = cachedPageNumber
                
                // assume we've loaded at least once, so return the local db instead
//                if loadedSoFar == stride {
//                    return self.dataStore.fetchMediaGospel(for: categoryUuid)
//                }
                if loadedSoFar >= totalEntries {
                    DDLogDebug("DataServiceError.offsetOutofRange: \(DataServiceError.offsetOutofRange)")
                    return dataStore.fetchMediaGospel(for: categoryUuid)
//                    return Single.error(DataServiceError.offsetOutofRange)
                }
            } catch {
                DDLogDebug("DataServiceError.decodeFailed: \(DataServiceError.decodeFailed)")
            }
        }
        
        switch self.networkStatus.value {
        case .notReachable:

            return dataStore.fetchMediaGospel(for: categoryUuid)
        case .reachable(_):
            var cachedMedia: [Playable]!
            
            // get cached gospel array
            let mediaMap: [String: [Playable]] = self._media.value
            if let result: [Playable] = mediaMap[String(describing: categoryUuid)] {
                cachedMedia = result
            } else {
                cachedMedia = []
            }


            // we should try to determine if we need to fetch more items
            // AND if we should then determine the next page offset should be fetched
            
            // fetch more == false if
            // - cacheedGospelItems.count < stride
            
            // fetch more == true if
            // - cacheedGospelItems.count divides evenly into stride(no remainder)
            
            let modulo: Int = cachedMedia.count % stride
            if modulo == 0 {
                previousOffset = (cachedMedia.count / stride)
            }

            if (loadedSoFar < totalEntries) || (fetchState == .hasNotFetched) && (cachedMedia.count == 0 || modulo == 0) {
                let moyaResponse = self.kjvrvgNetworking.rx.request(.gospelsMedia(uuid: categoryUuid, offset: previousOffset + 1, limit: stride)) //(.booksChapterMedia(uuid: categoryUuid, languageId: L10n.shared.language))
                let mediaGospelResponse: Single<MediaGospelResponse> = moyaResponse.map { response -> MediaGospelResponse in
                    do {
                        self._responseMap[categoryUuid] = response
                        return try response.map(MediaGospelResponse.self)
                    } catch {
                        throw DataServiceError.decodeFailed
                    }
                }
                let storedMediaGospel: Single<[Playable]> = mediaGospelResponse.flatMap { [unowned self] mediaGospelResponse -> Single<[Playable]> in
                    self.appendPersistedMediaGospel(mediaGospel: mediaGospelResponse.result, for: categoryUuid)
                }
                .do(onSuccess: { [unowned self] playble in
                    var mediaMap: [String: [Playable]] = self._media.value
                    mediaMap[categoryUuid] = playble
                    self._media.value = mediaMap
                })
                return storedMediaGospel
            } else {
                // return back cached gospel array
                let mediaMap: [String: [Playable]] = self._media.value
                //                    let gospelResult: [Categorizable]
                
                if let result: [Playable] = mediaMap[categoryUuid] {
                    return Single.just(result) // dataStore.fetchCategoryList(for: categoryType)
                } else {
                    return dataStore.fetchMediaGospel(for: categoryUuid)
                }
            }
        case .unknown:
            return dataStore.fetchMediaGospel(for: categoryUuid)
        }
    }

    public func mediaMusic(for categoryUuid: String, stride: Int) -> Single<[Playable]> {
        var mediaMusicResponse: MediaMusicResponse!
        var previousOffset = 0
        var totalEntries = -1
        var loadedSoFar = -1
        var fetchState: FetchState = .hasNotFetched
        
        if let cachedResponse: Response = self._responseMap[categoryUuid] {
            do {
                fetchState = .hasFetched
                
                mediaMusicResponse = try cachedResponse.map(MediaMusicResponse.self)
                totalEntries = mediaMusicResponse.totalEntries
                let cachedPageNumber: Int = mediaMusicResponse.pageNumber
                let cachedPageSize: Int = mediaMusicResponse.pageSize
                
                loadedSoFar = cachedPageNumber * cachedPageSize
                previousOffset = cachedPageNumber
                
                // assume we've loaded at least once, so return the local db instead
                //                if loadedSoFar == stride {
                //                    return self.dataStore.fetchMediaMusic(for: categoryUuid)
                //                }
                if loadedSoFar >= totalEntries {
                    DDLogDebug("DataServiceError.offsetOutofRange: \(DataServiceError.offsetOutofRange)")
                    return dataStore.fetchMediaMusic(for: categoryUuid)
                    //                    return Single.error(DataServiceError.offsetOutofRange)
                }
            } catch {
                DDLogDebug("DataServiceError.decodeFailed: \(DataServiceError.decodeFailed)")
            }
        }
        
        switch self.networkStatus.value {
        case .notReachable:
            
            return dataStore.fetchMediaMusic(for: categoryUuid)
        case .reachable(_):
            var cachedMedia: [Playable]!
            
            // get cached music media array
            let mediaMap: [String: [Playable]] = self._media.value
            if let result: [Playable] = mediaMap[String(describing: categoryUuid)] {
                cachedMedia = result
            } else {
                cachedMedia = []
            }
            
            
            // we should try to determine if we need to fetch more items
            // AND if we should then determine the next page offset should be fetched
            
            // fetch more == false if
            // - cacheedMusicItems.count < stride
            
            // fetch more == true if
            // - cacheedMusicItems.count divides evenly into stride(no remainder)
            
            let modulo: Int = cachedMedia.count % stride
            if modulo == 0 {
                previousOffset = (cachedMedia.count / stride)
            }
            
            if (loadedSoFar < totalEntries) || (fetchState == .hasNotFetched) && (cachedMedia.count == 0 || modulo == 0) {
                let moyaResponse = self.kjvrvgNetworking.rx.request(.musicMedia(uuid: categoryUuid, offset: previousOffset + 1, limit: stride)) //(.booksChapterMedia(uuid: categoryUuid, languageId: L10n.shared.language))
                let mediaMusicResponse: Single<MediaMusicResponse> = moyaResponse.map { response -> MediaMusicResponse in
                    do {
                        self._responseMap[categoryUuid] = response
                        return try response.map(MediaMusicResponse.self)
                    } catch {
                        throw DataServiceError.decodeFailed
                    }
                }
                let storedMediaMusic: Single<[Playable]> = mediaMusicResponse.flatMap { [unowned self] mediaMusicResponse -> Single<[Playable]> in
                    self.appendPersistedMediaMusic(mediaMusic: mediaMusicResponse.result, for: categoryUuid)
                    }
                    .do(onSuccess: { [unowned self] playble in
                        var mediaMap: [String: [Playable]] = self._media.value
                        mediaMap[categoryUuid] = playble
                        self._media.value = mediaMap
                    })
                return storedMediaMusic
            } else {
                // return back cached music media array
                let mediaMap: [String: [Playable]] = self._media.value
                //                    let gospelResult: [Categorizable]
                
                if let result: [Playable] = mediaMap[categoryUuid] {
                    return Single.just(result) // dataStore.fetchCategoryList(for: categoryType)
                } else {
                    return dataStore.fetchMediaMusic(for: categoryUuid)
                }
            }
        case .unknown:
            return dataStore.fetchMediaMusic(for: categoryUuid)
        }
    }

    public func bibleLanguages(stride: Int) -> Single<[LanguageIdentifier]> {
        var languageResponse: LanguagesSupportedResponse!
        var previousOffset = 0
        var totalEntries = -1
        var loadedSoFar = -1
        var fetchState: FetchState = .hasNotFetched
        
        if let cachedResponse: Response = self._responseMap["languagesResponse"] {
            do {
                fetchState = .hasFetched
                
                languageResponse = try cachedResponse.map(LanguagesSupportedResponse.self)
                totalEntries = languageResponse.totalEntries
                let cachedPageNumber: Int = languageResponse.pageNumber
                let cachedPageSize: Int = languageResponse.pageSize
                
                loadedSoFar = cachedPageNumber * cachedPageSize
                previousOffset = cachedPageNumber
                
                if loadedSoFar >= totalEntries {
                    DDLogDebug("DataServiceError.offsetOutofRange: \(DataServiceError.offsetOutofRange)")
                    return Single.error(DataServiceError.offsetOutofRange)
                }
            } catch {
                DDLogDebug("DataServiceError.decodeFailed: \(DataServiceError.decodeFailed)")
            }
        }
        
        
        switch self.networkStatus.value {
        case .unknown:
            return dataStore.fetchBibleLanguages()
        case .notReachable:
            return dataStore.fetchBibleLanguages()
        case .reachable(_):
            //        var categoryListing: Single<[LanguageIdentifier]> = Single.just([])
            return self.kjvrvgNetworking.rx.request(.languagesSupported(offset: previousOffset + 1, limit: stride))
                .map { response -> LanguagesSupportedResponse in
                    do {
                        // cache response for the next call
                        self._responseMap["languagesResponse"] = response
                        return try response.map(LanguagesSupportedResponse.self)
                    } catch {
                        throw DataServiceError.decodeFailed
                    }
                }.flatMap { languagesSupportedResponse -> Single<[LanguageIdentifier]> in
                    DDLogDebug("languagesSupportedResponse.result: \(languagesSupportedResponse.result)")
                    return Single.just(languagesSupportedResponse.result)
                }
                .flatMap { [unowned self] in self.replacePersistedBibleLanguages(bibleLanguages: $0) }
        }
    }

    public func categoryListing(for categoryType: CategoryListingType, stride: Int) -> Single<[Categorizable]> {
        var categoryListing: Single<[Categorizable]> = Single.just([])
        var musicResponse: MusicResponse!
        var gospelResponse: GospelResponse!
        
        var gospelPreviousOffset = 0
        var gospelTotalEntries = -1
        var gospelLoadedSoFar = -1
        
        var musicPreviousOffset = 0
        var musicTotalEntries = -1
        var musicLoadedSoFar = -1
        
        var gospelFetchState: FetchState = .hasNotFetched
        var musicFetchState: FetchState = .hasNotFetched
        
        /// optimization where we cache responses to avoid unnecessary network fetches
        if let cachedResponse: Response = self._responseMap[String(describing: categoryType)] {
            do {
                switch categoryType {
                case .gospel:
                    gospelFetchState = .hasFetched

                    gospelResponse = try cachedResponse.map(GospelResponse.self)
                    gospelTotalEntries = gospelResponse.totalEntries
                    let cachedPageNumber: Int = gospelResponse.pageNumber
                    let cachedPageSize: Int = gospelResponse.pageSize
                    
                    gospelLoadedSoFar = cachedPageNumber * cachedPageSize
                    gospelPreviousOffset = cachedPageNumber
                    
                    // assume we've loaded at least once, so return the local db instead
                    gospelLoadedSoFar = cachedPageNumber * cachedPageSize
                    gospelPreviousOffset = cachedPageNumber
                    
                    if gospelLoadedSoFar >= gospelTotalEntries {
                        DDLogDebug("DataServiceError.offsetOutofRange: \(DataServiceError.offsetOutofRange)")
//                        return Single.error(DataServiceError.offsetOutofRange)
                        return dataStore.fetchCategoryList(for: categoryType)
                    }
                case .music:
                    musicFetchState = .hasFetched

                    musicResponse = try cachedResponse.map(MusicResponse.self)
                    musicTotalEntries = musicResponse.totalEntries
                    let cachedPageNumber: Int = musicResponse.pageNumber
                    let cachedPageSize: Int = musicResponse.pageSize
                    
                    musicLoadedSoFar = cachedPageNumber * cachedPageSize
                    musicPreviousOffset = cachedPageNumber
                    
                    // assume we've loaded at least once, so return the local db instead
                    if musicLoadedSoFar >= musicTotalEntries {
                        DDLogDebug("DataServiceError.offsetOutofRange: \(DataServiceError.offsetOutofRange)")
                        //                        return Single.error(DataServiceError.offsetOutofRange)
                        return dataStore.fetchCategoryList(for: categoryType)
                    }
                case .mediaItems:
                    DDLogDebug(".mediaItems")
                }
                //                categoryResponse = try cachedResponse.map(MediaGospelResponse.self)
            } catch {
                DDLogDebug("DataServiceError.decodeFailed: \(DataServiceError.decodeFailed)")
            }
        }
        
        switch categoryType {
        case .gospel:
            switch self.networkStatus.value {
            case .unknown:
                categoryListing = dataStore.fetchCategoryList(for: categoryType)
            case .notReachable:
                categoryListing = dataStore.fetchCategoryList(for: categoryType)
            case .reachable(_):
                var cachedGospelItems: [Categorizable]!
                
                // get cached gospel array
                let categorizableMap: [String: [Categorizable]] = self._categories.value
                if let gospelResult: [Categorizable] = categorizableMap[String(describing: categoryType)] {
                    cachedGospelItems = gospelResult
                } else {
                    cachedGospelItems = []
                }

                // we should try to determine if we need to fetch more items
                // AND if we should then determine the next page offset should be fetched
                
                // fetch more == false if
                // - cacheedGospelItems.count < stride
                
                // fetch more == true if
                // - cacheedGospelItems.count divides evenly into stride(no remainder)
                
                let modulo: Int = cachedGospelItems.count % stride
                if modulo == 0 {
                    gospelPreviousOffset = (cachedGospelItems.count / stride)
                }

                if (gospelLoadedSoFar < gospelTotalEntries || gospelFetchState == .hasNotFetched) && (cachedGospelItems.count == 0 || modulo == 0) {
                    DDLogDebug("reachable")
                    categoryListing = self.kjvrvgNetworking.rx.request(.gospels(languageId: L10n.shared.language, offset: gospelPreviousOffset + 1, limit: stride))
                        .map { response -> GospelResponse in
                            do {
                                // cache response for the next call
                                self._responseMap[String(describing: categoryType)] = response
                                return try response.map(GospelResponse.self)
                            } catch {
                                throw DataServiceError.decodeFailed
                            }
                        }.flatMap { gospelResponse -> Single<[Categorizable]> in
                            DDLogDebug("gospelResponse.result: \(gospelResponse.result)")
                            return Single.just(gospelResponse.result)
                        }
                        .flatMap { [unowned self] in self.appendPersistedCategoryList(categoryList: $0, for: categoryType) }
                        .do(onSuccess: { [unowned self] categorizable in
                            var categorizableMap: [String: [Categorizable]] = self._categories.value
                            categorizableMap[String(describing: categoryType)] = categorizable
                            self._categories.value = categorizableMap
                            //            self._persistedBooks.value = products
                        })
                } else {
                    // return back cached gospel array
                    let categorizableMap: [String: [Categorizable]] = self._categories.value
//                    let gospelResult: [Categorizable]
                    
                    if let gospelResult: [Categorizable] = categorizableMap[String(describing: categoryType)] {
                        categoryListing = Single.just(gospelResult) // dataStore.fetchCategoryList(for: categoryType)
                    } else {
                        categoryListing = dataStore.fetchCategoryList(for: categoryType)
                    }
                }
            }
        case .music:
            DDLogDebug(".music")
            switch self.networkStatus.value {
            case .unknown:
                categoryListing = dataStore.fetchCategoryList(for: categoryType)
            case .notReachable:
                categoryListing = dataStore.fetchCategoryList(for: categoryType)
            case .reachable(_):
                var cachedMusicItems: [Categorizable]!

                // get cached music array
                let categorizableMap: [String: [Categorizable]] = self._categories.value
                if let musicResult: [Categorizable] = categorizableMap[String(describing: categoryType)] {
                    cachedMusicItems = musicResult
                } else {
                    cachedMusicItems = []
                }
                
                // we should try to determine if we need to fetch more items
                // AND if we should then determine the next page offset should be fetched
                
                // fetch more == false if
                // - cacheedMusicItems.count < stride
                
                // fetch more == true if
                // - cacheedMusicItems.count divides evenly into stride(no remainder)
                
                let modulo: Int = cachedMusicItems.count % stride
                if modulo == 0 {
                    musicPreviousOffset = (cachedMusicItems.count / stride)
                }
                if (musicLoadedSoFar < musicTotalEntries || musicFetchState == .hasNotFetched) && (cachedMusicItems.count == 0 || modulo == 0) {
                    DDLogDebug("reachable")
                    categoryListing = self.kjvrvgNetworking.rx.request(.music(languageId: L10n.shared.language, offset: musicPreviousOffset + 1, limit: stride))
                        .map { response -> MusicResponse in
                            do {
                                // cache response for the next call
                                self._responseMap[String(describing: categoryType)] = response
                                return try response.map(MusicResponse.self)
                            } catch {
                                throw DataServiceError.decodeFailed
                            }
                        }.flatMap { musicResponse -> Single<[Categorizable]> in
                            DDLogDebug("musicResponse.result: \(musicResponse.result)")
                            return Single.just(musicResponse.result)
                        }
                        .flatMap { [unowned self] in self.appendPersistedCategoryList(categoryList: $0, for: categoryType) }
                        .do(onSuccess: { [unowned self] categorizable in
                            var categorizableMap: [String: [Categorizable]] = self._categories.value
                            categorizableMap[String(describing: categoryType)] = categorizable
                            self._categories.value = categorizableMap
                            //            self._persistedBooks.value = products
                        })
                } else {
                    // return back cached music category array
                    let categorizableMap: [String: [Categorizable]] = self._categories.value
                    if let musicResult: [Categorizable] = categorizableMap[String(describing: categoryType)] {
                        categoryListing = Single.just(musicResult) // dataStore.fetchCategoryList(for: categoryType)
                    } else {
                        categoryListing = dataStore.fetchCategoryList(for: categoryType)
                    }
                }
            }
        case .mediaItems:
            DDLogDebug(".mediaItems")
        }
        return categoryListing
    }

    // MARK: Private helpers
    private func replacePersistedBooks(_ books: [Book]) -> Single<[Book]> {
        return dataStore.deleteAllBooks()
            .flatMap { [unowned self] in self.dataStore.addBooks(books: books) }
    }
    
    private func appendPersistedBooks(_ books: [Book]) -> Single<[Book]> {
        return self.dataStore.addBooks(books: books)
//            .do(onSuccess: { [unowned self] books in
//                return self.dataStore.fetchBooks()
//            })
    }
    
    public func deletePersistedBooks() -> Single<Void> {
        return self.dataStore.deleteAllBooks()
    }
    
    private func loadBooks() -> Observable<[Book]> {
        return dataStore.fetchBooks()
            //            .asObservable()
            .do(
                onNext: { [weak self] books in
                    self?._books.value = books
                },
                onError: { [weak self] error in
                    DDLogDebug("error: \(error.localizedDescription)")
                    self?._books.value = []
            })
            .asObservable()
    }
    private func loadCategory(for categoryListingType: CategoryListingType) -> Observable<String> {
        return dataStore.fetchCategoryList(for: categoryListingType)
            .do(onSuccess: { [unowned self] categorizable in
                var categoryMap: [String: [Categorizable]] = self._categories.value
                categoryMap[String(describing: categoryListingType)] = categorizable
                self._categories.value = categoryMap
            })
            .map { categorizableArray in
                return categorizableArray.map { categorizable -> String in
                    DDLogDebug("categorizable: \((categorizable))")
                    return categorizable.categoryUuid
                }
            }
            .asObservable()
            .flatMap { Observable.from($0) }
    }

    private func replacePersistedChapters(chapters: [Playable], for bookUuid: String) -> Single<[Playable]> {
        let deleted: Single<Void> = dataStore.deleteChapters(for: bookUuid)
        return deleted.flatMap { [unowned self] _ in self.dataStore.addChapters(chapters: chapters, for: bookUuid) }
    }

//    private func replacePersistedChapters(chapters: [Playable], for bookUuid: String) -> Single<[Playable]> {
//        return self.dataStore.addChapters(chapters: chapters, for: bookUuid)
//    }
    
    private func appendPersistedChapters(chapters: [Playable], for bookUuid: String) -> Single<[Playable]> {
//        let deleted: Single<Void> = dataStore.deleteChapters(for: bookUuid)
        return self.dataStore.addChapters(chapters: chapters, for: bookUuid)
    }

    private func replacePersistedMediaGospel(mediaGospel: [Playable], for categoryUuid: String) -> Single<[Playable]> {
        let deleted: Single<Void> = dataStore.deleteMediaGospel(for: categoryUuid)
        return deleted.flatMap { [unowned self] _ in self.dataStore.addMediaGospel(mediaGospel: mediaGospel, for: categoryUuid) }
    }
    
    private func appendPersistedMediaGospel(mediaGospel: [Playable], for categoryUuid: String) -> Single<[Playable]> {
        return self.dataStore.addMediaGospel(mediaGospel: mediaGospel, for: categoryUuid)
    }

    private func replacePersistedMediaMusic(mediaMusic: [Playable], for categoryUuid: String) -> Single<[Playable]> {
        let deleted: Single<Void> = dataStore.deleteMediaMusic(for: categoryUuid)
        return deleted.flatMap { [unowned self] _ in self.dataStore.addMediaMusic(mediaMusic: mediaMusic, for: categoryUuid) }
    }

    private func appendPersistedMediaMusic(mediaMusic: [Playable], for categoryUuid: String) -> Single<[Playable]> {
        return self.dataStore.addMediaMusic(mediaMusic: mediaMusic, for: categoryUuid)
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

    private func appendPersistedCategoryList(categoryList: [Categorizable],
                                              for categoryListType: CategoryListingType) -> Single<[Categorizable]> {
        return self.dataStore.addCategory(categoryList: categoryList, for: categoryListType)
    }

    private func reactToReachability() {
        reachability.startListening().asObservable()
            .subscribe(onNext: { networkStatus in
                self.networkStatus.value = networkStatus
                if networkStatus == .notReachable {
                    DDLogDebug("DataService reachability.notReachable")
                } else if networkStatus == .reachable(.ethernetOrWiFi) {
                    DDLogDebug("DataService reachability.reachable")
                }
            }).disposed(by: bag)
    }
}
