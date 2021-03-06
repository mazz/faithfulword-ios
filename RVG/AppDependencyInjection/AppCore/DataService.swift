import RxSwift
import Moya
import L10n_swift
import Alamofire
import os.log

public enum DataServiceError: Error {
    case noSession
    case noAccessToken
    case decodeFailed
    case offsetOutofRange
}

public enum CacheDirective {
    case use
    case bypass
    case fetchAndReplace
    case fetchAndAppend
}

public protocol UserDataServicing {
    var languageIdentifier: Observable<String> { get }
    func updateUserLanguage(identifier: String) -> Single<String>
    func fetchUserLanguage() -> Single<String>
}

public protocol UserActionsDataServicing {
    func updatePlaybackPosition(playable: Playable, position: Float, duration: Float) -> Single<Void>
    //    func fetchPlaybackPosition(playable: Playable) -> Single<Double>
}

public protocol HistoryDataServicing {
    func playableHistory(limit: Int) -> Single<[Playable]>
    func fetchLastUserActionPlayableState(for playableUuid: String) -> Single<UserActionPlayable?>
    //    func fetchPlaybackPosition(playable: Playable) -> Single<Double>
}

protocol FileDownloadDataServicing {
    func updateFileDownloadHistory(fileDownload: FileDownload) -> Single<Void>
    func fetchLastFileDownloadHistory(playableUuid: String) -> Single<FileDownload?>
    func deleteLastFileDownloadHistory(playableUuid: String) -> Single<Void>
    func deleteFileDownloadFile(playableUuid: String, pathExtension: String) -> Single<Void>
    
    func updateFileDownloads(playableUuids: [String], to state: FileDownloadState) -> Single<Void>
    // list
    func fileDownloads(for playlistUuid: String) -> Single<[FileDownload]>
    func allFileDownloads() -> Single<[FileDownload]>
    func fetchInterruptedDownloads(_ playlistUuid: String?) -> Single<[FileDownload]>
}

public protocol SearchDataServicing {
    func searchMediaItems(query: String,
                          mediaCategory: String?,
                          playlistUuid: String?,
                          channelUuid: String?,
                          publishedAfter: TimeInterval?,
                          updatedAfter: TimeInterval?,
                          presentedAfter: TimeInterval?,
                          offset: Int,
                          limit: Int,
                          cacheDirective: CacheDirective) -> Single<(MediaItemResponse, [MediaItem])>
    
}
// Provides account related data to the app
public protocol AccountDataServicing {
    
    /// Permanent observable providing session objects.
    var token: Observable<String?> { get }
    var loginUser: Observable<UserLoginUser?> { get }
    
    func loginUser(email: String, password: String) -> Single<UserLoginResponse>
    func signupUser(user: [String: AnyHashable]) -> Single<UserSignupResponse>
    func addAppUser(user: UserAppUser) -> Single<Void>
    //    func addLoginUser(user: UserLoginUser) -> Single<Void>
    func fetchAppUser() -> Single<UserAppUser?>
    func replacePersistedAppUser(user: UserAppUser) -> Single<UserAppUser>
    //    func fetchLoginUser() -> Single<UserLoginUser>
    func fetchLoginUser() -> Single<UserLoginUser?>
    func appendPersistedLoginUser(user: UserLoginUser) -> Single<UserLoginUser>
    func replacePersistedLoginUser(user: UserLoginUser) -> Single<UserLoginUser>
    
}

/// Provides product related data to the app
public protocol ProductDataServicing {
    
    func persistedMediaItems(for playlistUuid: String) -> Single<[MediaItem]>
    func fetchMediaItem(mediaItemUuid: String) -> Single<MediaItem>
    func fetchMediaItemForHashId(hashId: String) -> Single<MediaItem>
    func fetchAndObserveMediaItems(for playlistUuid: String, offset: Int, limit: Int, cacheDirective: CacheDirective) -> Single<(MediaItemResponse, [MediaItem])>
    
    func persistedPlaylists(for channelUuid: String) -> Single<[Playlist]>
    func fetchAndObservePlaylists(for channelUuid: String, offset: Int, limit: Int, cacheDirective: CacheDirective) -> Single<(PlaylistResponse, [Playlist])>
    
    func deletePlaylists() -> Single<Void>
    func deletePlaylists(_ forChannelUuid: String) -> Single<Void>
    
    func persistedChannels(for orgUuid: String) -> Single<[Channel]>
    func fetchAndObserveChannels(for orgUuid: String, offset: Int, limit: Int) -> Single<[Channel]>
    
    func persistedDefaultOrgs() -> Single<[Org]>
    func persistedDefaultOrg() -> Single<Org?>
    func fetchAndObserveDefaultOrgs(offset: Int, limit: Int) -> Single<[Org]>
    func deletePersistedDefaultOrgs() -> Single<Void>
    func deletePersistedChannels() -> Single<Void>
    //    func orgs(offset: Int, limit: Int) -> Single<[Org]>
    
    // ~~~~~~~~~~~
    
    var books: Observable<[Book]> { get }
    var orgs: Observable<[Org]> { get }
    var channels: Observable<[Channel]> { get }
    
    func chapters(for bookUuid: String, stride: Int) -> Single<[Playable]>
    func fetchAndObserveBooks(stride: Int) -> Single<[Book]>
    func deletePersistedBooks() -> Single<Void>
    
    func mediaGospel(for categoryUuid: String, stride: Int) -> Single<[Playable]>
    func mediaMusic(for categoryUuid: String, stride: Int) -> Single<[Playable]>
    func bibleLanguages(stride: Int) -> Single<[LanguageIdentifier]>
    
    func categoryListing(for categoryType: CategoryListingType, stride: Int) -> Single<[Categorizable]>
    
    // new-ish API for forthcoming org-channel-playlist changes
    // TODO: once the schema from the server contains mediaType, there
    // will be no need to LEFT JOIN in DataStore because we know which table
    // among book, gospel and music to find the playables
    func playables(for categoryUuid: String) -> Single<[Playable]>
}

public final class DataService {
    
    // MARK: Dependencies
    
    private let dataStore: DataStoring
    private let networkingApi: MoyaProvider<FwbcApiService>!
    private let reachability: RxClassicReachable!
    
    // MARK: Fields
    
    private var networkStatus = Field<ClassicReachability.NetworkStatus>(.unknown)
    private let bag = DisposeBag()
    
    // MARK: UserDataServicing
    private var _orgs = Field<[Org]>([])
    private var _channels = Field<[Channel]>([])
    
    private var _languageIdentifier = Field<String>("test init identifier")
    
    // MARK: AccountDataServicing
    private var _token = Field<String?>(nil)
    private var _user = Field<UserLoginUser?>(nil)
    // MARK: ProductDataServicing
    private var _books = Field<[Book]>([])
    private var _categories = Field<[String: [Categorizable]]>([:])
    private var _media = Field<[String: [Playable]]>([:])
    
    private var _responseMap: [String: Response] = [:]
    private var _persistedBooks = Field<[Book]>([])
    
    internal init(
        dataStore: DataStoring,
        networkingApi: MoyaProvider<FwbcApiService>,
        reachability: RxClassicReachable) {
        self.dataStore = dataStore
        self.networkingApi = networkingApi
        self.reachability = reachability
        
        reactToReachability()
        //        loadInMemoryCache()
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

extension DataService: UserActionsDataServicing {
    public func updatePlaybackPosition(playable: Playable, position: Float, duration: Float) -> Single<Void> {
        //        DDLogDebug("updatePlaybackPosition(playable: \(playable) position: \(position)")
        return dataStore.updatePlayableHistory(playable: playable, position: position, duration: duration)
        //        return Single.just(())
    }
    
    //    public func fetchPlaybackPosition(playable: Playable) -> Single<Double> {
    //        DDLogDebug("fetchPlaybackPosition(playable: \(playable)")
    //        return Single.just(5.0)
    //    }
}

extension DataService: HistoryDataServicing {
    public func playableHistory(limit: Int) -> Single<[Playable]> {
        return dataStore.playableHistory(limit: limit)
    }
    
    public func fetchLastUserActionPlayableState(for playableUuid: String) -> Single<UserActionPlayable?> {
        return dataStore.fetchLastUserActionPlayableState(playableUuid: playableUuid)
    }
}

extension DataService: FileDownloadDataServicing {
    func updateFileDownloadHistory(fileDownload: FileDownload) -> Single<Void> {
        return dataStore.updateFileDownloadHistory(fileDownload: fileDownload)
    }
    
    public func fetchLastFileDownloadHistory(playableUuid: String) -> Single<FileDownload?> {
        return dataStore.fetchLastFileDownloadHistory(playableUuid: playableUuid)
    }
    
    public func deleteLastFileDownloadHistory(playableUuid: String) -> Single<Void> {
        return dataStore.deleteLastFileDownloadHistory(playableUuid: playableUuid)
    }
    
    func deleteFileDownloadFile(playableUuid: String, pathExtension: String) -> Single<Void> {
        return dataStore.deleteFileDownloadFile(playableUuid: playableUuid, pathExtension: pathExtension)
    }
    
    
    public func updateFileDownloads(playableUuids: [String], to state: FileDownloadState) -> Single<Void> {
        return dataStore.updateFileDownloads(playableUuids: playableUuids, to: state)
    }
    
    public func fileDownloads(for playlistUuid: String) -> Single<[FileDownload]> {
        return dataStore.fileDownloads(for: playlistUuid)
    }
    
    public func allFileDownloads() -> Single<[FileDownload]> {
        return dataStore.allFileDownloads()
    }
    
    public func fetchInterruptedDownloads(_ playlistUuid: String? = nil) -> Single<[FileDownload]> {
        return dataStore.fetchInterruptedDownloads(playlistUuid)
    }
}

extension DataService: SearchDataServicing {
    public func searchMediaItems(query: String,
                                 mediaCategory: String?,
                                 playlistUuid: String?,
                                 channelUuid: String?,
                                 publishedAfter: TimeInterval?,
                                 updatedAfter: TimeInterval?,
                                 presentedAfter: TimeInterval?,
                                 offset: Int,
                                 limit: Int,
                                 cacheDirective: CacheDirective) -> Single<(MediaItemResponse, [MediaItem])> {
        
        let moyaResponse = self.networkingApi.rx.request(.search(query: query,
                                                                 mediaCategory: mediaCategory,
                                                                 playlistUuid: playlistUuid,
                                                                 channelUuid: channelUuid,
                                                                 publishedAfter: publishedAfter,
                                                                 updatedAfter: updatedAfter,
                                                                 presentedAfter: presentedAfter,
                                                                 offset: offset,
                                                                 limit: limit))
        
        let response: Single<MediaItemResponse> = moyaResponse.map { response -> MediaItemResponse in
            do {
                let jsonObj = try response.mapJSON()
                DDLogDebug("jsonObj: \(jsonObj)")
                return try response.map(MediaItemResponse.self)
            } catch {
                DDLogError("Moya decode error: \(error)")
                throw DataServiceError.decodeFailed
            }
        }
        
        return response.flatMap { [unowned self] response -> Single<(MediaItemResponse, [MediaItem])> in
            //            let mediaItems: Single<[MediaItem]> = self.appendPersistedMediaItems(mediaItems: response.result)
            let mediaItems: Single<[MediaItem]> = Single.just(response.result)
            return mediaItems.map({ items -> (MediaItemResponse, [MediaItem]) in
                let tuple: (MediaItemResponse, [MediaItem]) = (response, items)
                return tuple
            })
        }
    }
    
    
}

extension DataService: AccountDataServicing {
    
    public func loginUser(email: String, password: String) -> Single<UserLoginResponse> {
        let moyaResponse = self.networkingApi.rx.request(.userLogin(email: email, password: password))
        let response: Single<UserLoginResponse> = moyaResponse.map { response in
            do {
                let jsonObj = try response.mapJSON()
                DDLogDebug("jsonObj: \(jsonObj)")
                return try response.map(UserLoginResponse.self)
            } catch {
                DDLogError("Moya decode error: \(error)")
                throw DataServiceError.decodeFailed
            }
            
        }
        .do(onSuccess: { [unowned self] loginResponse in
            self._token.value = loginResponse.token
            self._user.value = loginResponse.user
        })
        return response
        
    }
    
    public func signupUser(user: [String: AnyHashable]) -> Single<UserSignupResponse> {
        let moyaResponse = self.networkingApi.rx.request(.userSignup(user: user))
        let response: Single<UserSignupResponse> = moyaResponse.map { response in
            do {
                let jsonObj = try response.mapJSON()
                DDLogDebug("jsonObj: \(jsonObj)")
                return try response.map(UserSignupResponse.self)
            } catch {
                DDLogError("Moya decode error: \(error)")
                throw DataServiceError.decodeFailed
            }
            
        }
        .do(onSuccess: { [unowned self] signupResponse in
            self._token.value = signupResponse.token
            self._user.value = signupResponse.user
        })
        return response
    }
    
    public var user: Single<UserLoginUser?> {
        return Single.just(_user.value)
    }
    
    
    public var token: Observable<String?> { return _token.asObservable() }
    public var loginUser: Observable<UserLoginUser?> { return _user.asObservable() }
    
    // MARK: Helpers
    public func addAppUser(user: UserAppUser) -> Single<Void> {
        return self.dataStore.addAppUser(addingUser: user)
            .toVoid()
    }
    
    public func fetchAppUser() -> Single<UserAppUser?> {
        return self.dataStore.fetchAppUser()
    }
    
    public func replacePersistedAppUser(user: UserAppUser) -> Single<UserAppUser> {
        return dataStore.deleteAppUser()
            .flatMap { [unowned self] _ in
                self.dataStore.addAppUser(addingUser: user)
        }
    }
    
    public func appendPersistedLoginUser(user: UserLoginUser) -> Single<UserLoginUser> {
        return self.dataStore.addLoginUser(addingUser: user)
    }
    
    public func fetchLoginUser() -> Single<UserLoginUser?> {
        return self.dataStore.fetchLoginUser()
    }
    
    public func replacePersistedLoginUser(user: UserLoginUser) -> Single<UserLoginUser> {
        return dataStore.deleteLoginUser()
            .flatMap { [unowned self] _ in
                self.dataStore.addLoginUser(addingUser: user)
        }
    }
}

enum FetchState {
    case hasFetched
    case hasNotFetched
}

extension DataService: ProductDataServicing {
    
    public var orgs: Observable<[Org]> {
        switch self.networkStatus.value {
        case .notReachable:
            DDLogDebug("DataService reachability.notReachable")
            return _orgs.asObservable()
        case .reachable(_):
            DDLogDebug("DataService reachability.reachable")
            return _orgs.asObservable()
        case .unknown:
            DDLogDebug("DataService reachability.unknown")
            return _orgs.asObservable()
        }
    }
    
    public func persistedDefaultOrgs() -> Single<[Org]> {
        return dataStore.fetchDefaultOrgs()
            .do(onSuccess: { [unowned self] orgs in
                self._orgs.value = orgs
            })
    }
    
    public func persistedDefaultOrg() -> Single<Org?> {
        return dataStore.fetchDefaultOrg()
    }
    
    public func fetchAndObserveDefaultOrgs(offset: Int, limit: Int) -> Single<[Org]> {
        let moyaResponse = self.networkingApi.rx.request(.defaultOrgs(offset: offset, limit: limit))
        let response: Single<OrgResponse> = moyaResponse.map { response -> OrgResponse in
            do {
                let jsonObj = try response.mapJSON()
                //                DDLogDebug("jsonObj: \(jsonObj)")
                return try response.map(OrgResponse.self)
            } catch {
                DDLogError("Moya decode error: \(error)")
                throw DataServiceError.decodeFailed
            }
        }
        return response.flatMap { [unowned self] response -> Single<[Org]> in
            //            DDLogDebug("response.result: \(response.result)")
            return self.replacePersistedDefaultOrgs(orgs: response.result)
        }
        .do(onSuccess: { [unowned self] products in
            self._orgs.value = products
        })
    }
    
    
    // MARK: MediaItems
    
    public func persistedMediaItems(for playlistUuid: String) -> Single<[MediaItem]> {
        return dataStore.fetchMediaItems(for: playlistUuid)
    }
    
    public func fetchMediaItem(mediaItemUuid: String) -> Single<MediaItem> {
        let moyaResponse = self.networkingApi.rx.request(.mediaItem(uuid: mediaItemUuid))
        let response: Single<MediaItemRouteResponse> = moyaResponse.map { response -> MediaItemRouteResponse in
            do {
                let jsonObj = try response.mapJSON()
                DDLogDebug("jsonObj: \(jsonObj)")
                return try response.map(MediaItemRouteResponse.self)
            } catch {
                DDLogError("Moya decode error: \(error)")
                throw DataServiceError.decodeFailed
            }
        }
        let mediaItem = response.map { mediaItemRouteResponse -> MediaItem in
            return mediaItemRouteResponse.result
        }
        return mediaItem
    }
    
    public func fetchMediaItemForHashId(hashId: String) -> Single<MediaItem> {
        let moyaResponse = self.networkingApi.rx.request(.mediaItemForHashId(hashId: hashId))
        let response: Single<MediaItemRouteResponse> = moyaResponse.map { response -> MediaItemRouteResponse in
            do {
                let jsonObj = try response.mapJSON()
                os_log("jsonObj: %{public}@", log: OSLog.data, String(describing: jsonObj))

                return try response.map(MediaItemRouteResponse.self)
            } catch {
                os_log("Moya decode error: %{public}@", log: OSLog.data, String(describing: error))

                throw DataServiceError.decodeFailed
            }
        }
        let mediaItem = response.map { mediaItemRouteResponse -> MediaItem in
            return mediaItemRouteResponse.result
        }
        return mediaItem
    }
    
    public func fetchAndObserveMediaItems(for playlistUuid: String, offset: Int, limit: Int, cacheDirective: CacheDirective) -> Single<(MediaItemResponse, [MediaItem])> {
        let moyaResponse = self.networkingApi.rx.request(.mediaItems(uuid: playlistUuid, languageId: L10n.shared.language, offset: offset, limit: limit))
        let response: Single<MediaItemResponse> = moyaResponse.map { response -> MediaItemResponse in
            do {
                let jsonObj = try response.mapJSON()
                DDLogDebug("jsonObj: \(jsonObj)")
                return try response.map(MediaItemResponse.self)
            } catch {
                DDLogError("Moya decode error: \(error)")
                throw DataServiceError.decodeFailed
            }
        }
        
        return response.flatMap { [unowned self] response -> Single<(MediaItemResponse, [MediaItem])> in
            let mediaItems: Single<[MediaItem]> = self.appendPersistedMediaItems(mediaItems: response.result) //appendPersistedPlaylists(playlists: response.result)
            return mediaItems.map({ items -> (MediaItemResponse, [MediaItem]) in
                let tuple: (MediaItemResponse, [MediaItem]) = (response, items)
                return tuple
            })
        }
    }
    
    // MARK: Playlists
    
    public func persistedPlaylists(for channelUuid: String) -> Single<[Playlist]> {
        return dataStore.fetchPlaylists(for: channelUuid)
    }
    
    public func fetchAndObservePlaylists(for channelUuid: String, offset: Int, limit: Int, cacheDirective: CacheDirective) -> Single<(PlaylistResponse, [Playlist])> {
        
        // if the cacheDirective is .fetchAndReplace then also fetch
        // if the persisted channel is older than the
        let moyaResponse = self.networkingApi.rx.request(.playlists(uuid: channelUuid, languageId: L10n.shared.language, offset: offset, limit: limit))
        let response: Single<PlaylistResponse> = moyaResponse.map { response -> PlaylistResponse in
            do {
                //                let jsonObj = try response.mapJSON()
                //                DDLogDebug("jsonObj: \(jsonObj)")
                return try response.map(PlaylistResponse.self)
            } catch {
                DDLogError("Moya decode error: \(error)")
                throw DataServiceError.decodeFailed
            }
        }
        
        return response.flatMap { [unowned self] response -> Single<(PlaylistResponse, [Playlist])> in
            let playlist: Single<[Playlist]> = self.appendPersistedPlaylists(playlists: response.result)
            return playlist.map({ playlist -> (PlaylistResponse, [Playlist]) in
                let tuple: (PlaylistResponse, [Playlist]) = (response, playlist)
                return tuple
            })
        }
    }
    
    public func deletePlaylists() -> Single<Void> {
        return dataStore.deletePlaylists()
    }

    public func deletePlaylists(_ forChannelUuid: String) -> Single<Void> {
        return dataStore.deletePlaylists(forChannelUuid)
    }
    
    // MARK: Channels
    
    public var channels: Observable<[Channel]> {
        switch self.networkStatus.value {
        case .notReachable:
            DDLogDebug("DataService reachability.notReachable")
            return _channels.asObservable()
        case .reachable(_):
            DDLogDebug("DataService reachability.reachable")
            return _channels.asObservable()
        case .unknown:
            DDLogDebug("DataService reachability.unknown")
            return _channels.asObservable()
        }
    }
    
    public func persistedChannels(for orgUuid: String) -> Single<[Channel]> {
        return dataStore.fetchChannels(for: orgUuid)
            .do(onSuccess: { [unowned self] channels in
                self._channels.value = channels
            })
    }
    
    public func fetchAndObserveChannels(for orgUuid: String, offset: Int, limit: Int) -> Single<[Channel]> {
        let moyaResponse = self.networkingApi.rx.request(.channels(uuid: orgUuid, offset: offset, limit: limit))
        let response: Single<ChannelResponse> = moyaResponse.map { response -> ChannelResponse in
            do {
                let jsonObj = try response.mapJSON()
                //                DDLogDebug("jsonObj: \(jsonObj)")
                return try response.map(ChannelResponse.self)
            } catch {
                DDLogError("Moya decode error: \(error)")
                throw DataServiceError.decodeFailed
            }
        }
        return response.flatMap { [unowned self] response -> Single<[Channel]> in
            //            DDLogDebug("response.result: \(response.result)")
            return self.replacePersistedChannels(channels: response.result)
        }
        .do(onSuccess: { [unowned self] products in
            self._channels.value = products
        })
    }
    
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
            
            let moyaResponse = self.networkingApi.rx.request(.booksChapterMedia(uuid: bookUuid, languageId: L10n.shared.language, offset: previousOffset + 1, limit: stride))
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
                return self.replacePersistedChapters(chapters: mediaChapterResponse.result, for: bookUuid)
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
                return self.networkingApi.rx.request(.books(languageId: L10n.shared.language, offset: previousOffset + 1, limit: stride))
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
                let moyaResponse = self.networkingApi.rx.request(.gospelsMedia(uuid: categoryUuid, offset: previousOffset + 1, limit: stride)) //(.booksChapterMedia(uuid: categoryUuid, languageId: L10n.shared.language))
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
                let moyaResponse = self.networkingApi.rx.request(.musicMedia(uuid: categoryUuid, offset: previousOffset + 1, limit: stride)) //(.booksChapterMedia(uuid: categoryUuid, languageId: L10n.shared.language))
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
        return self.networkingApi.rx.request(.languagesSupported(offset: 0, limit: stride))
            .map { response -> LanguagesSupportedResponse in
                do {
                    return try response.map(LanguagesSupportedResponse.self)
                } catch {
                    DDLogError("Moya decode error: \(error)")
                    throw DataServiceError.decodeFailed
                }
        }.flatMap { languagesSupportedResponse -> Single<[LanguageIdentifier]> in
            DDLogDebug("languagesSupportedResponse.result: \(languagesSupportedResponse.result)")
            return Single.just(languagesSupportedResponse.result)
        }
        .flatMap { [unowned self] in self.replacePersistedBibleLanguages(bibleLanguages: $0) }
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
                case .preaching:
                    DDLogDebug(".preaching")
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
                    categoryListing = self.networkingApi.rx.request(.gospels(languageId: L10n.shared.language, offset: gospelPreviousOffset + 1, limit: stride))
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
                    categoryListing = self.networkingApi.rx.request(.music(languageId: L10n.shared.language, offset: musicPreviousOffset + 1, limit: stride))
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
        case .preaching:
            DDLogDebug(".preaching")
        }
        return categoryListing
    }
    
    // Orgs ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    private func replacePersistedDefaultOrgs(orgs: [Org]) -> Single<[Org]> {
        return dataStore.deleteDefaultOrgs()
            .flatMap { [unowned self] _ in
                self.dataStore.addDefaultOrgs(orgs: orgs)
        }
    }
    
    public func deletePersistedDefaultOrgs() -> Single<Void> {
        return self.dataStore.deleteDefaultOrgs()
    }
    
    // Channels ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    private func replacePersistedChannels(channels: [Channel]) -> Single<[Channel]> {
        return dataStore.deleteChannels()
            .flatMap { [unowned self] _ in
                self.dataStore.addChannels(channels: channels)
        }
    }
    
    public func deletePersistedChannels() -> Single<Void> {
        return self.dataStore.deleteChannels()
    }
    
    // MediaItems ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    private func appendPersistedMediaItems(mediaItems: [MediaItem]) -> Single<[MediaItem]> {
        return self.dataStore.addMediaItems(items: mediaItems)
    }
    
    private func replacePersistedMediaItems(mediaItems: [MediaItem]) -> Single<[MediaItem]> {
        return dataStore.deleteMediaItems()
            .flatMap { [unowned self] _ in
                self.dataStore.addMediaItems(items: mediaItems)
        }
    }
    
    public func deletePersistedMediaItems() -> Single<Void> {
        return self.dataStore.deleteMediaItems()
    }
    
    
    // Playlists ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    private func appendPersistedPlaylists(playlists: [Playlist]) -> Single<[Playlist]> {
        return self.dataStore.addPlaylists(playlists: playlists)
    }
    
    private func replacePersistedPlaylists(playlists: [Playlist]) -> Single<[Playlist]> {
        return dataStore.deletePlaylists()
            .flatMap { [unowned self] _ in
                self.dataStore.addPlaylists(playlists: playlists)
        }
    }
    
    public func deletePersistedPlaylists() -> Single<Void> {
        return self.dataStore.deletePlaylists()
    }
    
    // Books ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
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
                onSuccess: { [weak self] books in
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
        reachability.startNotifier().asObservable()
            .subscribe(onNext: { networkStatus in
                self.networkStatus.value = networkStatus
                
                switch networkStatus {
                case .unknown:
                    DDLogDebug("DataService \(self.reachability.status.value)")
                case .notReachable:
                    DDLogDebug("DataService \(self.reachability.status.value)")
                case .reachable(_):
                    DDLogDebug("DataService \(self.reachability.status.value)")
                }
            }).disposed(by: bag)
    }
    
    public func playables(for categoryUuid: String) -> Single<[Playable]> {
        return dataStore.fetchPlayables(for: categoryUuid)
    }
}


