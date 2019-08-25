import RxSwift
import GRDB
import L10n_swift

/// Protocol for storing and retrieving data from Realm database
public protocol DataStoring {
    //    func latestCachedUser() -> Single<String?>
    
    func fetchDefaultOrgs() -> Single<[Org]>
    func addDefaultOrgs(orgs: [Org]) -> Single<[Org]>
    func deleteDefaultOrgs() -> Single<Void>

    func fetchChannels(for channelUuid: String) -> Single<[Channel]>
    func addChannels(channels: [Channel]) -> Single<[Channel]>
    func deleteChannels() -> Single<Void>

    func fetchPlaylists(for channelUuid: String) -> Single<[Playlist]>
    func addPlaylists(playlists: [Playlist]) -> Single<[Playlist]>
    func deletePlaylists() -> Single<Void>

    func fetchMediaItems(for playlistUuid: String) -> Single<[MediaItem]>
    func addMediaItems(items: [MediaItem]) -> Single<[MediaItem]>
    func deleteMediaItems() -> Single<Void>

    func addUser(addingUser: UserAppUser) -> Single<UserAppUser>
    func fetchUser() -> Single<UserAppUser>
    func addLoginUser(addingUser: UserLoginUser) -> Single<UserLoginUser>
    
//    func addUser(session: String) -> Single<String>
    //    func updateUserLanguage(identifier: String) -> Single<String>
    func updateUserLanguage(identifier: String) -> Single<String>
    func fetchUserLanguage() -> Single<String>
    
    func addBooks(books: [Book]) -> Single<[Book]>
    func fetchBooks() -> Single<[Book]>
    func deleteAllBooks() -> Single<Void>
    
    func addChapters(chapters: [Playable], for bookUuid: String) -> Single<[Playable]>
    func fetchChapters(for bookUuid: String) -> Single<[Playable]>
    func deleteChapters(for bookUuid: String) -> Single<Void>
    
    func addMediaGospel(mediaGospel: [Playable], for categoryUuid: String) -> Single<[Playable]>
    func fetchMediaGospel(for categoryUuid: String) -> Single<[Playable]>
    func deleteMediaGospel(for categoryUuid: String) -> Single<Void>
    
    func addMediaMusic(mediaMusic: [Playable], for categoryUuid: String) -> Single<[Playable]>
    func fetchMediaMusic(for categoryUuid: String) -> Single<[Playable]>
    func deleteMediaMusic(for categoryUuid: String) -> Single<Void>
    
    func addBibleLanguages(bibleLanguages: [LanguageIdentifier]) -> Single<[LanguageIdentifier]>
    func fetchBibleLanguages() -> Single<[LanguageIdentifier]>
    func deleteBibleLanguages() -> Single<Void>
    
    func addCategory(categoryList: [Categorizable],
                     for categoryListType: CategoryListingType) -> Single<[Categorizable]>
    func deleteCategoryList(for categoryListingType: CategoryListingType) -> Single<Void>
    func fetchCategoryList(for categoryListingType: CategoryListingType) -> Single<[Categorizable]>
    
    // MARK: history
    
    func updatePlayableHistory(playable: Playable, position: Float, duration: Float) -> Single<Void>
    func fetchPlayableHistory() -> Single<[Playable]>
    func fetchLastUserActionPlayableState(playableUuid: String) -> Single<UserActionPlayable?>
    
    // MARK: FileDownload
    
    func updateFileDownloadHistory(fileDownload: FileDownload) -> Single<Void>
    func fetchLastFileDownloadHistory(playableUuid: String) -> Single<FileDownload?>
    func deleteLastFileDownloadHistory(playableUuid: String) -> Single<Void>
    func deleteFileDownloadFile(playableUuid: String, pathExtension: String) -> Single<Void>
    
    func updateFileDownloads(playableUuids: [String], to state: FileDownloadState) -> Single<Void>
    
    // MARK: FileDownload list
    func fileDownloads(for playlistUuid: String) -> Single<[FileDownload]>
    
    // MARK: Playlist
    func fetchPlayables(for categoryUuid: String) -> Single<[Playable]>

    //    func fetchPlaybackHistory(playable: Playable, position: Float) -> Single<Float>
}

public enum DataStoreError: Error {
    case databaseOpenFailed
}

/// Storage class holding reference to realm object
public final class DataStore {
    
    internal var _dbPool: DatabasePool?
    
    // MARK: Dependencies
    public var dbPool: DatabasePool {
        let documentsURL: URL = getDocumentsDirectory()
        let databasePath = documentsURL.appendingPathComponent("db.sqlite")
        return try! openDatabase(atPath: databasePath.absoluteString)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    /// The DatabaseMigrator that defines the database schema.
    // See https://github.com/groue/GRDB.swift/#migrations
    internal var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1.3") { db in
            do {
                try db.create(table: "org") { orgTable in
                    DDLogDebug("created: \(orgTable)")
                    //                orgTable.column("chapterId", .integer).primaryKey()
                    
                    orgTable.column("uuid", .text).primaryKey()
                    orgTable.column("bannerPath", .text)
                    orgTable.column("basename", .text)
                    orgTable.column("shortname", .text)
                    orgTable.column("insertedAt", .double)
                    orgTable.column("updatedAt", .double)
                    orgTable.column("largeThumbnailPath", .text)
                    orgTable.column("medThumbnailPath", .text)
                    orgTable.column("smallThumbnailPath", .text)
                }
            }
            catch {
                DDLogDebug("error making org table: \(error)")
            }

            do {
                try db.create(table: "channel") { channelTable in
                    DDLogDebug("created: \(channelTable)")
                    //                orgTable.column("chapterId", .integer).primaryKey()
                    
                    channelTable.column("uuid", .text).primaryKey()
                    channelTable.column("orgUuid", .text).references("org", onDelete: .cascade)
                    channelTable.column("bannerPath", .text)
                    channelTable.column("basename", .text)
                    channelTable.column("ordinal", .integer)
                    channelTable.column("insertedAt", .double)
                    channelTable.column("updatedAt", .double)
                    channelTable.column("largeThumbnailPath", .text)
                    channelTable.column("medThumbnailPath", .text)
                    channelTable.column("smallThumbnailPath", .text)
                }
            }
            catch {
                DDLogDebug("error making channel table: \(error)")
            }
            do {
                try db.create(table: "playlist") { playlistTable in
                    DDLogDebug("created: \(playlistTable)")
                    playlistTable.column("uuid", .text).primaryKey()
                    playlistTable.column("channelUuid", .text).references("channel", onDelete: .cascade)
                    playlistTable.column("bannerPath", .text)
                    playlistTable.column("localizedname", .text)
                    playlistTable.column("languageId", .text)
                    playlistTable.column("mediaCategory", .text)
                    playlistTable.column("ordinal", .integer)
                    playlistTable.column("insertedAt", .double)
                    playlistTable.column("updatedAt", .double)
                    playlistTable.column("largeThumbnailPath", .text)
                    playlistTable.column("medThumbnailPath", .text)
                    playlistTable.column("smallThumbnailPath", .text)
                }
            }
            catch {
                DDLogDebug("error making playlist table: \(error)")
            }
            do {
                try db.create(table: "mediaitem") { mediaItemTable in
                    DDLogDebug("created: \(mediaItemTable)")
                    mediaItemTable.column("contentProviderLink", .text)
                    mediaItemTable.column("duration", .double)
                    mediaItemTable.column("hashId", .text)
                    mediaItemTable.column("insertedAt", .double)
                    mediaItemTable.column("ipfsLink", .text)
                    mediaItemTable.column("languageId", .text)
                    mediaItemTable.column("localizedname", .text)
                    mediaItemTable.column("largeThumbnailPath", .text)
                    mediaItemTable.column("mediaCategory", .text)
                    mediaItemTable.column("medium", .text)
                    mediaItemTable.column("medThumbnailPath", .text)
                    mediaItemTable.column("ordinal", .integer)
                    mediaItemTable.column("path", .text)
                    mediaItemTable.column("playlistUuid", .text).references("playlist", onDelete: .cascade)
                    mediaItemTable.column("presentedAt", .double)
                    mediaItemTable.column("presenterName", .text)
                    mediaItemTable.column("publishedAt", .double)
                    mediaItemTable.column("smallThumbnailPath", .text)
                    mediaItemTable.column("sourceMaterial", .text)
                    mediaItemTable.column("tags", .text)
                    mediaItemTable.column("trackNumber", .integer)
                    mediaItemTable.column("updatedAt", .double)

                    mediaItemTable.column("uuid", .text).primaryKey()
                }
            }
            catch {
                DDLogDebug("error making mediaitem table: \(error)")
            }
            
            do {
                try db.create(table: "userloginuser") { loginUserTable in
                    DDLogDebug("created: \(loginUserTable)")
                    loginUserTable.column("achievements", .text)
                    loginUserTable.column("email", .text)
                    loginUserTable.column("email_confirmed", .boolean)
                    loginUserTable.column("fb_user_id", .integer)
                    loginUserTable.column("id", .integer)
                    loginUserTable.column("is_publisher", .boolean)
                    loginUserTable.column("locale", .text)
                    loginUserTable.column("mini_picture_url", .text)
                    loginUserTable.column("name", .text)
                    loginUserTable.column("picture_url", .text)
                    loginUserTable.column("registered_at", .double)
                    loginUserTable.column("reputation", .integer)
                    loginUserTable.column("username", .text)
                    loginUserTable.column("uuid", .text).primaryKey()
                }
            }
            catch {
                DDLogDebug("error making userloginuser table: \(error)")
            }

            do {
                try db.create(table: "userappuser") { userTable in
                    DDLogDebug("created: \(userTable)")
                    userTable.column("uuid", .text).primaryKey()
                    userTable.column("userId", .integer)
                    userTable.column("name", .text)
                    userTable.column("email", .text)
                    userTable.column("session", .text)
                    userTable.column("pushNotifications", .boolean)
                    userTable.column("language", .text)
                    userTable.column("userLoginUserUuid", .text).references("userloginuser", onDelete: .cascade)
                }
            }
            catch {
                DDLogDebug("error making user table: \(error)")
            }
            
            do {
                try db.create(table: "book") { bookTable in
                    DDLogDebug("created: \(bookTable)")
                    bookTable.column("categoryUuid", .text).primaryKey()
                    bookTable.column("title", .text)
                    bookTable.column("languageId", .text)
                    bookTable.column("localizedTitle", .text)
//                    bookTable.column("uuid", .text).references("user", onDelete: .cascade)
                }
            }
            catch {
                DDLogDebug("error making book table: \(error)")
            }
            
            do {
                try db.create(table: "mediachapter") { chapterTable in
                    DDLogDebug("created: \(chapterTable)")
                    //                chapterTable.column("chapterId", .integer).primaryKey()
                    chapterTable.column("uuid", .text).primaryKey()
                    chapterTable.column("localizedName", .text)
                    chapterTable.column("path", .text)
                    chapterTable.column("presenterName", .text)
                    chapterTable.column("sourceMaterial", .text)
                    chapterTable.column("trackNumber", .integer)
                    chapterTable.column("createdAt", .double)
                    chapterTable.column("duration", .double)
                    chapterTable.column("updatedAt", .double)
                    chapterTable.column("largeThumbnailPath", .text)
                    chapterTable.column("smallThumbnailPath", .text)
                    chapterTable.column("categoryUuid", .text).references("book", onDelete: .cascade)
                }
            }
            catch {
                DDLogDebug("error making mediachapter table: \(error)")
            }
            
            do {
                try db.create(table: "gospel") { gospelTable in
                    DDLogDebug("created: \(gospelTable)")
                    gospelTable.column("categoryUuid", .text).primaryKey()
                    gospelTable.column("title", .text)
                    gospelTable.column("languageId", .text)
                    gospelTable.column("localizedTitle", .text)
//                    gospelTable.column("uuid", .text).references("user", onDelete: .cascade)
                }
            }
            catch {
                DDLogDebug("error making gospel table: \(error)")
            }
            
            do {
                try db.create(table: "mediagospel") { gospelTable in
                    DDLogDebug("created: \(gospelTable)")
                    //                chapterTable.column("chapterId", .integer).primaryKey()
                    gospelTable.column("uuid", .text).primaryKey()
                    gospelTable.column("localizedName", .text)
                    gospelTable.column("path", .text)
                    gospelTable.column("presenterName", .text)
                    gospelTable.column("sourceMaterial", .text)
                    gospelTable.column("trackNumber", .integer)
                    gospelTable.column("createdAt", .double)
                    gospelTable.column("duration", .double)
                    gospelTable.column("updatedAt", .double)
                    gospelTable.column("largeThumbnailPath", .text)
                    gospelTable.column("smallThumbnailPath", .text)
                    gospelTable.column("categoryUuid", .text).references("gospel", onDelete: .cascade)
                }
            }
            catch {
                DDLogDebug("error making mediagospel table: \(error)")
            }
            
            do {
                try db.create(table: "music") { musicTable in
                    DDLogDebug("created: \(musicTable)")
                    musicTable.column("categoryUuid", .text).primaryKey()
                    musicTable.column("title", .text)
                    musicTable.column("languageId", .text)
                    musicTable.column("localizedTitle", .text)
//                    musicTable.column("uuid", .text).references("user", onDelete: .cascade)
                }
            }
            catch {
                DDLogDebug("error making gospel table: \(error)")
            }
            
            do {
                try db.create(table: "mediamusic") { musicTable in
                    DDLogDebug("created: \(musicTable)")
                    //                chapterTable.column("chapterId", .integer).primaryKey()
                    musicTable.column("uuid", .text).primaryKey()
                    musicTable.column("localizedName", .text)
                    musicTable.column("path", .text)
                    musicTable.column("presenterName", .text)
                    musicTable.column("sourceMaterial", .text)
                    musicTable.column("trackNumber", .integer)
                    musicTable.column("createdAt", .double)
                    musicTable.column("duration", .double)
                    musicTable.column("updatedAt", .double)
                    musicTable.column("largeThumbnailPath", .text)
                    musicTable.column("smallThumbnailPath", .text)
                    musicTable.column("categoryUuid", .text).references("music", onDelete: .cascade)
                }
            }
            catch {
                DDLogDebug("error making mediagospel table: \(error)")
            }
            
            do {
                try db.create(table: "languageidentifier") { langTable in
                    DDLogDebug("created: \(langTable)")
                    langTable.column("uuid", .text).primaryKey()
                    langTable.column("sourceMaterial", .text)
                    langTable.column("languageIdentifier", .text)
                    langTable.column("supported", .boolean)
                }
            }
            catch {
                DDLogDebug("error making languageidentifier table: \(error)")
            }
            do {
                try db.create(table: "useractionplayable") { userActionPlayableTable in
                    DDLogDebug("created: \(userActionPlayableTable)")
                    userActionPlayableTable.column("downloaded", .boolean)
                    userActionPlayableTable.column("duration", .double)
                    userActionPlayableTable.column("hashId", .text)
                    userActionPlayableTable.column("playableUuid", .text)
                    userActionPlayableTable.column("playablePath", .text)
                    userActionPlayableTable.column("playbackPosition", .double)
                    userActionPlayableTable.column("updatedAt", .double)
//                    userActionPlayableTable.column("userActionPlayableId", .integer)
                    userActionPlayableTable.column("uuid", .text).primaryKey()

                    // Playable
                    userActionPlayableTable.column("insertedAt", .double)
                    userActionPlayableTable.column("largeThumbnailPath", .text)
                    userActionPlayableTable.column("localizedname", .text)
                    userActionPlayableTable.column("mediaCategory", .text)
                    userActionPlayableTable.column("medThumbnailPath", .text)
                    userActionPlayableTable.column("path", .text)
                    userActionPlayableTable.column("playlistUuid", .text)
                    userActionPlayableTable.column("presenterName", .text)
                    userActionPlayableTable.column("sourceMaterial", .text)
                    userActionPlayableTable.column("smallThumbnailPath", .text)
                    userActionPlayableTable.column("trackNumber", .integer)
                }
            }
            catch {
                DDLogDebug("error making useractionplayable table: \(error)")
            }
            do {
                try db.create(table: "filedownload") { downloadsTable in
                    DDLogDebug("created: \(downloadsTable)")
                    downloadsTable.column("uuid", .text).primaryKey()
                    downloadsTable.column("playableUuid", .text)
                    downloadsTable.column("url", .text)
                    downloadsTable.column("localUrl", .text)
                    downloadsTable.column("progress", .double)
                    downloadsTable.column("totalCount", .integer)
                    downloadsTable.column("completedCount", .integer)
                    downloadsTable.column("updatedAt", .double)
                    downloadsTable.column("insertedAt", .double)
                    downloadsTable.column("state", .integer)
//                    downloadsTable.column("userUuid", .text).references("user", onDelete: .cascade)
                    downloadsTable.column("extendedDescription", .text)
                    downloadsTable.column("playlistUuid", .text)
                }
            }
            catch {
                DDLogDebug("error making downloads table: \(error)")
            }
        }
        return migrator
    }
    
    internal func openDatabase(atPath path: String) throws -> DatabasePool {
        var resultPool: DatabasePool!
        
        if let databasePool = _dbPool {
            resultPool = databasePool
            return resultPool
        } else {
            // Connect to the database
            // See https://github.com/groue/GRDB.swift/#database-connections
            _dbPool = try DatabasePool(path: path)
            DDLogDebug("new _dbPool at databasePath: \(path)")
            
            if let databasePool = _dbPool {
                // Use DatabaseMigrator to define the database schema
                // See https://github.com/groue/GRDB.swift/#migrations
                try migrator.migrate(databasePool)
                resultPool = databasePool
                return resultPool
            }
        }
        return resultPool
    }
}



// MARK: <DataStoring>
extension DataStore: DataStoring {
    // MARK: Org
    
    public func fetchDefaultOrgs() -> Single<[Org]> {
        return Single.create { [unowned self] single in
            do {
                var fetchOrgs: [Org] = []
                //                let chapters: [Org]!
                try self.dbPool.read { db in
                    fetchOrgs = try Org.fetchAll(db)
                }
                single(.success(fetchOrgs))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }

    
    public func addDefaultOrgs(orgs: [Org]) -> Single<[Org]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    //                    if let user = try User.fetchOne(db) {
                    for org in orgs {
                        DDLogDebug("org: \(org)")
                        //            try! self.dbQueue.inDatabase { db in
                        var storeOrg: Org = org
                        //                            storeLang.userId = user.userId
                        try storeOrg.insert(db)
                    }
                    //                    }
                    return .commit
                }
                single(.success(orgs))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func deleteDefaultOrgs() -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    try Org.deleteAll(db)
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create()
        }
    }

    //MARK: Channel
    
    public func fetchChannels(for orgUuid: String) -> Single<[Channel]> {
        return Single.create { [unowned self] single in
            do {
                var fetched: [Channel] = []
                try self.dbPool.read { db in
                    fetched = try Channel.filter(Column("orgUuid") == orgUuid).fetchAll(db)
                }
                single(.success(fetched))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func addChannels(channels: [Channel]) -> Single<[Channel]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    //                    if let user = try User.fetchOne(db) {
                    for channel in channels {
                        DDLogDebug("channel: \(channel)")
                        //            try! self.dbQueue.inDatabase { db in
                        var storeChannel: Channel = channel
                        //                            storeLang.userId = user.userId
                        try storeChannel.insert(db)
                    }
                    //                    }
                    return .commit
                }
                single(.success(channels))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func deleteChannels() -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    try Channel.deleteAll(db)
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create()
        }
    }

    //MARK: Playlist
    
    public func fetchPlaylists(for channelUuid: String) -> Single<[Playlist]> {
        return Single.create { [unowned self] single in
            do {
                var fetched: [Playlist] = []
                try self.dbPool.read { db in
                    fetched = try Playlist.filter(Column("channelUuid") == channelUuid).fetchAll(db)
                }
                single(.success(fetched))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func addPlaylists(playlists: [Playlist]) -> Single<[Playlist]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    //                    if let user = try User.fetchOne(db) {
                    for playlist in playlists {
                        DDLogDebug("playlist: \(playlist)")
                        //            try! self.dbQueue.inDatabase { db in
                        var storePlaylist: Playlist = playlist
                        //                            storeLang.userId = user.userId
                        try storePlaylist.insert(db)
                    }
                    //                    }
                    return .commit
                }
                single(.success(playlists))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func deletePlaylists() -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    try Playlist.deleteAll(db)
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create()
        }
    }
    
    // MARK: MediaItems
    public func fetchMediaItems(for playlistUuid: String) -> Single<[MediaItem]> {
        return Single.create { [unowned self] single in
            do {
                var fetched: [MediaItem] = []
                try self.dbPool.read { db in
                    fetched = try MediaItem.filter(Column("playlistUuid") == playlistUuid).fetchAll(db)
                }
                single(.success(fetched))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }

    public func addMediaItems(items: [MediaItem]) -> Single<[MediaItem]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    //                    if let user = try User.fetchOne(db) {
                    for mediaItem in items {
                        DDLogDebug("mediaItem: \(mediaItem)")
                        //            try! self.dbQueue.inDatabase { db in
                        var storeMediaItem: MediaItem = mediaItem
                        //                            storeLang.userId = user.userId
                        try storeMediaItem.insert(db)
                    }
                    //                    }
                    return .commit
                }
                single(.success(items))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func deleteMediaItems() -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    try MediaItem.deleteAll(db)
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create()
        }
    }

    //MARK: User
    
    // will error if there is already one user because for now
    // this is a single-user app
    public func addUser(addingUser: UserAppUser) -> Single<UserAppUser> {
        return Single.create { [unowned self] single in
            var resultUser: UserAppUser = addingUser
            do {
                try self.dbPool.writeInTransaction { db in
                    if try UserAppUser.fetchCount(db) == 0 {
                        
//                        var user = User(userId: nil,
//                                        uuid: NSUUID().uuidString,
//                                        name: "name",
//                                        email: "test@test",
//                                        session: session,
//                                        pushNotifications:false,
//                                        language: L10n.shared.language) //(userId: nil, name: "john hancock", session: session, pushNotifications: false, language: L10n.shared.language)
                        try resultUser.insert(db)
//                        resultUser = user.session
                    }
                    return .commit
                }
                single(.success(resultUser))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
        //        return Single.just("")
    }

    public func fetchUser() -> Single<UserAppUser> {
        return Single.create { [unowned self] single in
            do {
                var fetchUser: UserAppUser!
                try self.dbPool.read { db in
                    if let user = try UserAppUser.fetchOne(db) {
                        fetchUser = user
                    }
                }
                single(.success(fetchUser))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func addLoginUser(addingUser: UserLoginUser) -> Single<UserLoginUser> {
        return Single.create { [unowned self] single in
            var resultUser: UserLoginUser = addingUser
            do {
                try self.dbPool.writeInTransaction { db in
                    try resultUser.insert(db)
                    //                        resultUser = user.session
                    //                    }
                    return .commit
                }
                single(.success(resultUser))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    
//    public func addUser(session: String) -> Single<String> {
//        return Single.create { [unowned self] single in
//            var resultSession: String = session
//            do {
//                try self.dbPool.writeInTransaction { db in
//                    if try UserAppUser.fetchCount(db) == 0 {
//
//                        var user = UserAppUser(userId: nil,
//                                        uuid: NSUUID().uuidString,
//                                        name: "name",
//                                        email: "test@test",
//                                        session: session,
//                                        pushNotifications:false,
//                                        language: L10n.shared.language) //(userId: nil, name: "john hancock", session: session, pushNotifications: false, language: L10n.shared.language)
//                        try user.insert(db)
//                        resultSession = user.session
//                    }
//                    return .commit
//                }
//                single(.success(resultSession))
//            } catch {
//                DDLogDebug("error: \(error)")
//                single(.error(error))
//            }
//            return Disposables.create {}
//        }
//        //        return Single.just("")
//    }
    
    // MARK: User Update
    
    public func updateUser(updatingUser: UserAppUser) -> Single<UserAppUser> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    if let user = try UserAppUser.filter(Column("uuid") == updatingUser.uuid).fetchOne(db) {
                        var storeUser: UserAppUser = user
                        storeUser.name = updatingUser.name
                        storeUser.session = updatingUser.session
                        storeUser.pushNotifications = updatingUser.pushNotifications
                        storeUser.language = updatingUser.language
                        try storeUser.update(db)
                    }
                    return .commit
                }
                single(.success(updatingUser))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
//    public func updateUser(updatingUser: User) -> Single<Void> {
//        return Single.create { [unowned self] single in
//            do {
//                try self.dbPool.writeInTransaction { db in
//                    if let book = try User.filter(Column("categoryUuid") == bookUuid).fetchOne(db) {
//
//                    if let user = try User.fetchOne(db) {
//                        var storeUser: User = user
//                        storeUser.language = identifier
//                        try storeUser.update(db)
//                    }
//                    return .commit
//                }
//                single(.success(identifier))
//            } catch {
//                DDLogDebug("error: \(error)")
//                single(.error(error))
//            }
//            return Disposables.create {}
//        }
////        return Single.create { [unowned self] single in
////            do {
////                try self.dbPool.writeInTransaction { db in
////                    if let user = try User.fetchOne(db) {
////                        var storeUser: User = user
////                        storeUser.language = identifier
////                        try storeUser.update(db)
////                    }
////                    return .commit
////                }
////                single(.success(identifier))
////            } catch {
////                DDLogDebug("error: \(error)")
////                single(.error(error))
////            }
////            return Disposables.create {}
////        }
//    }
    
    // MARK: -- User Language
    
    public func updateUserLanguage(identifier: String) -> Single<String> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    if let user = try UserAppUser.fetchOne(db) {
                        var storeUser: UserAppUser = user
                        storeUser.language = identifier
                        try storeUser.update(db)
                    }
                    return .commit
                }
                single(.success(identifier))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func fetchUserLanguage() -> Single<String> {
        return Single.create { [unowned self] single in
            do {
                var language: String = ""
                try self.dbPool.read { db in
                    if let user = try UserAppUser.fetchOne(db) {
                        language = user.language
                    }
                }
                single(.success(language))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    // MARK: Categories
    
    public func addCategory(categoryList: [Categorizable],
                            for categoryListType: CategoryListingType) -> Single<[Categorizable]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    if let user = try UserAppUser.fetchOne(db) {
                        for category in categoryList {
                            DDLogDebug("category: \(category)")
                            switch categoryListType {
                                
                            case .gospel:
                                DDLogDebug("writing .gospel")
                                var storeGospel: Gospel = category as! Gospel
                                storeGospel.userId = user.userId
                                try storeGospel.insert(db)
                            case .music:
                                DDLogDebug("writing .music")
                                var storeMusic: Music = category as! Music
                                storeMusic.userId = user.userId
                                try storeMusic.insert(db)
                            case .preaching:
                                DDLogDebug("writing .preaching")
                            }
                        }
                    }
                    return .commit
                }
                var fetchCategoryList: [Categorizable] = []
                try self.dbPool.read { db in
                    switch categoryListType {
                    case .gospel:
                        DDLogDebug("fetch .gospel")
                        fetchCategoryList = try Gospel.fetchAll(db)
                    case .music:
                        DDLogDebug("fetch .music")
                        fetchCategoryList = try Music.fetchAll(db)
                    case .preaching:
                        DDLogDebug(".preaching")
                    }
                }
                single(.success(fetchCategoryList))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func deleteCategoryList(for categoryListingType: CategoryListingType) -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    switch categoryListingType {
                    case .gospel:
                        DDLogDebug("delete .gospel")
                        try Gospel.deleteAll(db)
                    case .music:
                        DDLogDebug("delete .music")
                        try Music.deleteAll(db)
                    case .preaching:
                        DDLogDebug(".preaching")
                    }
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create()
        }
    }
    
    public func fetchCategoryList(for categoryListingType: CategoryListingType) -> Single<[Categorizable]> {
        return Single.create { [unowned self] single in
            do {
                var fetchCategoryList: [Categorizable] = []
                try self.dbPool.read { db in
                    switch categoryListingType {
                    case .gospel:
                        DDLogDebug("fetch .gospel")
                        fetchCategoryList = try Gospel.fetchAll(db)
                    case .music:
                        DDLogDebug("fetch .music")
                        fetchCategoryList = try Music.fetchAll(db)
                    case .preaching:
                        DDLogDebug(".preaching")
                    }
                }
                single(.success(fetchCategoryList))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    // MARK: Chapters
    
    public func addChapters(chapters: [Playable], for bookUuid: String) -> Single<[Playable]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    //                    let statement = try db.makeSelectStatement("SELECT * FROM book WHERE bid = ?")
                    if let book = try Book.filter(Column("categoryUuid") == bookUuid).fetchOne(db) {
                        DDLogDebug("found chapter book: \(book)")
//                        for chapter in chapters {
//                            var mediaChapter = MediaChapter(uuid: chapter.uuid,
//                                                            localizedName: chapter.localizedName,
//                                                            path: chapter.path,
//                                                            presenterName: chapter.presenterName,
//                                                            sourceMaterial: chapter.sourceMaterial,
//                                                            categoryUuid: book.categoryUuid,
//                                                            trackNumber: chapter.trackNumber,
//                                                            createdAt: chapter.createdAt,
//                                                            updatedAt: chapter.updatedAt,
//                                                            largeThumbnailPath: chapter.largeThumbnailPath,
//                                                            smallThumbnailPath: chapter.smallThumbnailPath
//                            )
//                            try mediaChapter.insert(db)
//                        }
                    }
                    return .commit
                }
                var fetchChapters: [Playable] = []
                //                let chapters: [Playable]!
                try self.dbPool.read { db in
                    fetchChapters = try MediaChapter.filter(Column("categoryUuid") == bookUuid).fetchAll(db)
                }
                single(.success(fetchChapters))
                //                single(.success(chapters))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
        
        //        return Single.just([])
    }
    
    public func fetchChapters(for bookUuid: String) -> Single<[Playable]> {
        return Single.create { [unowned self] single in
            do {
                var fetchChapters: [Playable] = []
                //                let chapters: [Playable]!
                try self.dbPool.read { db in
                    fetchChapters = try MediaChapter.filter(Column("categoryUuid") == bookUuid).fetchAll(db)
                }
                single(.success(fetchChapters))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func deleteChapters(for bookUuid: String) -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    
                    //                    let selectBook = try db.makeSelectStatement("SELECT * FROM book WHERE bid = ?")
                    if let _ = try Book.filter(Column("categoryUuid") == bookUuid).fetchOne(db) {
                        try MediaChapter.filter(Column("categoryUuid") == bookUuid).deleteAll(db)
                    }
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create()
        }
        //        return Single.just(())
    }
    
    // MARK: MediaGospel
    
    public func addMediaGospel(mediaGospel: [Playable], for categoryUuid: String) -> Single<[Playable]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    //                    let statement = try db.makeSelectStatement("SELECT * FROM book WHERE bid = ?")
                    if let gospel = try Gospel.filter(Column("categoryUuid") == categoryUuid).fetchOne(db) {
                        DDLogDebug("found gospel: \(gospel)")
//                        for media in mediaGospel {
//                            var mediaGospel = MediaGospel(uuid: media.uuid,
//                                                          localizedName: media.localizedName,
//                                                          path: media.path,
//                                                          presenterName: media.presenterName,
//                                                          sourceMaterial: media.sourceMaterial,
//                                                          categoryUuid: gospel.categoryUuid,
//                                                          trackNumber: media.trackNumber,
//                                                          createdAt: media.createdAt,
//                                                          updatedAt: media.updatedAt,
//                                                          largeThumbnailPath: media.largeThumbnailPath,
//                                                          smallThumbnailPath: media.smallThumbnailPath
//                            )
//                            try mediaGospel.insert(db)
//                        }
                    }
                    return .commit
                }
                
                // return ALL entries
                var fetchMediaGospel: [Playable] = []
                try self.dbPool.read { db in
                    fetchMediaGospel = try MediaGospel.filter(Column("categoryUuid") == categoryUuid).fetchAll(db)
                }
                single(.success(fetchMediaGospel))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func fetchMediaGospel(for categoryUuid: String) -> Single<[Playable]> {
        return Single.create { [unowned self] single in
            do {
                var fetchMediaGospel: [Playable] = []
                try self.dbPool.read { db in
                    fetchMediaGospel = try MediaGospel.filter(Column("categoryUuid") == categoryUuid).fetchAll(db)
                }
                single(.success(fetchMediaGospel))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func deleteMediaGospel(for categoryUuid: String) -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    //                    let selectBook = try db.makeSelectStatement("SELECT * FROM book WHERE bid = ?")
                    if let _ = try Gospel.filter(Column("categoryUuid") == categoryUuid).fetchOne(db) {
                        try MediaGospel.filter(Column("categoryUuid") == categoryUuid).deleteAll(db)
                    }
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create()
        }
        //        return Single.just(())
    }
    
    
    // MARK: MediaMusic
    
    public func addMediaMusic(mediaMusic: [Playable], for categoryUuid: String) -> Single<[Playable]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    //                    let statement = try db.makeSelectStatement("SELECT * FROM book WHERE bid = ?")
                    if let music = try Music.filter(Column("categoryUuid") == categoryUuid).fetchOne(db) {
                        DDLogDebug("found music: \(music)")
//                        for media in mediaMusic {
//                            var mediaMusic = MediaMusic(uuid: media.uuid,
//                                                        localizedName: media.localizedName,
//                                                        path: media.path,
//                                                        presenterName: media.presenterName,
//                                                        sourceMaterial: media.sourceMaterial,
//                                                        categoryUuid: music.categoryUuid,
//                                                        trackNumber: media.trackNumber,
//                                                        createdAt: media.createdAt,
//                                                        updatedAt: media.updatedAt,
//                                                        largeThumbnailPath: media.largeThumbnailPath,
//                                                        smallThumbnailPath: media.smallThumbnailPath
//                            )
//                            try mediaMusic.insert(db)
//                        }
                    }
                    return .commit
                }
                
                // return ALL entries
                var fetchMediaMusic: [Playable] = []
                try self.dbPool.read { db in
                    fetchMediaMusic = try MediaMusic.filter(Column("categoryUuid") == categoryUuid).fetchAll(db)
                }
                single(.success(fetchMediaMusic))
                //
                //                single(.success(mediaMusic))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func fetchMediaMusic(for categoryUuid: String) -> Single<[Playable]> {
        return Single.create { [unowned self] single in
            do {
                var fetchMediaMusic: [Playable] = []
                try self.dbPool.read { db in
                    fetchMediaMusic = try MediaMusic.filter(Column("categoryUuid") == categoryUuid).fetchAll(db)
                }
                single(.success(fetchMediaMusic))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func deleteMediaMusic(for categoryUuid: String) -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    //                    let selectBook = try db.makeSelectStatement("SELECT * FROM book WHERE bid = ?")
                    if let _ = try Music.filter(Column("categoryUuid") == categoryUuid).fetchOne(db) {
                        try MediaMusic.filter(Column("categoryUuid") == categoryUuid).deleteAll(db)
                    }
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create()
        }
        //        return Single.just(())
    }
    
    // MARK: Bible Languages
    
    public func addBibleLanguages(bibleLanguages: [LanguageIdentifier]) -> Single<[LanguageIdentifier]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    //                    if let user = try User.fetchOne(db) {
                    for bibleLanguage in bibleLanguages {
                        DDLogDebug("bibleLanguage: \(bibleLanguage)")
                        //            try! self.dbQueue.inDatabase { db in
                        var storeLang: LanguageIdentifier = bibleLanguage
                        //                            storeLang.userId = user.userId
                        try storeLang.insert(db)
                    }
                    //                    }
                    return .commit
                }
                single(.success(bibleLanguages))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func fetchBibleLanguages() -> Single<[LanguageIdentifier]> {
        return Single.create { [unowned self] single in
            do {
                
                var languages: [LanguageIdentifier] = []
                try self.dbPool.read { db in
                    languages = try LanguageIdentifier.fetchAll(db)
                }
                single(.success(languages))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func deleteBibleLanguages() -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    try LanguageIdentifier.deleteAll(db)
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create()
        }
    }
    
    // MARK: Books
    
    // always return ALL books, even when appending
    public func addBooks(books: [Book]) -> Single<[Book]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    if let user = try UserAppUser.fetchOne(db) {
                        for book in books {
                            DDLogDebug("book: \(book)")
                            //            try! self.dbQueue.inDatabase { db in
                            var storeBook: Book = book
                            storeBook.userId = user.userId
                            try storeBook.insert(db)
                        }
                    }
                    return .commit
                }
                var fetchBooks: [Book] = []
                try self.dbPool.read { db in
                    fetchBooks = try Book.fetchAll(db)
                }
                single(.success(fetchBooks))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    public func fetchBooks() -> Single<[Book]> {
        return Single.create { [unowned self] single in
            do {
                var fetchBooks: [Book] = []
                try self.dbPool.read { db in
                    fetchBooks = try Book.fetchAll(db)
                }
                single(.success(fetchBooks))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    
    public func deleteAllBooks() -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    let books = try Book.fetchAll(db)
                    for book in books {
                        try book.delete(db)
                    }
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create()
        }
    }
    
    // MARK: User Actions
    
    public func updatePlayableHistory(playable: Playable, position: Float, duration: Float) -> Single<Void> {
        // let update: Single<Void> =
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    // update
                    DDLogDebug("try action update playable.uuid: \(playable.uuid)")
                    if let action = try UserActionPlayable.filter(Column("playableUuid") == playable.uuid).fetchOne(db) {
                        // update existing action
                        
//                        DDLogDebug("action found: \(action) playable.uuid: \(playable.uuid)")
                        
                        // media that we will store the actual playback position
                        let storePlayableDuration: [MediaCategory] = [.preaching]
                        
                        if let playablePath = playable.path,
                            let prodUrl: URL = URL(string: playablePath) {
                            let pathExtension: String = prodUrl.pathExtension
                            let fileUrl: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(playable.uuid.appending(String(describing: ".\(pathExtension)"))).path)
                            let downloaded: Bool = FileManager.default.fileExists(atPath: fileUrl.path)
                            
//                            playable.duration = TimeInterval(duration)
                            DDLogDebug("file there update? \(downloaded)")
                            
                            // back up 5 seconds to help the user remember the context, unless < 0
//                            var newPosition: Double = Double(position)
//                            newPosition = newPosition - 5
//                            if newPosition < Double(0) { newPosition = Double(0) }
                            
                            // db update
                            var storeAction: UserActionPlayable = action
//                            storeAction.playbackPosition = Double(position)
                            
                            // reset progress if there is less than 10 seconds left to play
                            var storePosition: Float = position

                            if let category = MediaCategory(rawValue: storeAction.mediaCategory) {
                                if duration > 0 {
                                    let timeToEnd: Float = duration - position
                                    
                                    // if we are near the end, set position to 0
                                    if timeToEnd < 10 {
                                        storePosition = 0
                                    }
                                }
                                // if we are currently playing .preaching then store actual playback position because
                                // preaching content is typically long duration
                                storeAction.playbackPosition = (storePlayableDuration.contains(category)) ? Double(storePosition) : Double(0)
                            } else {
                                storeAction.playbackPosition = Double(0)
                            }
                            
                            storeAction.updatedAt = Date().timeIntervalSince1970
                            storeAction.downloaded = downloaded
                            try storeAction.update(db)
                        }
                        
                    } else {
                        // insert new action
                        DDLogDebug("action not found, playable.uuid: \(playable.uuid)")
                        if let playablePath = playable.path,
                            let prodUrl: URL = URL(string: playablePath)
                        {
                            let pathExtension: String = prodUrl.pathExtension
                            let fileUrl: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(playable.uuid.appending(String(describing: ".\(pathExtension)"))).path)
                            let downloaded: Bool = FileManager.default.fileExists(atPath: fileUrl.path)
                            DDLogDebug("file there insert? \(downloaded)")
                            
                            // back up 5 seconds to help the user remember the context, unless < 0
//                            var newPosition: Double = Double(position)
//                            newPosition = newPosition - 5
//                            if newPosition < Double(0) { newPosition = Double(0) }
                            
                            let newAction: UserActionPlayable =
                                UserActionPlayable(downloaded: downloaded,
                                                   duration: playable.duration,
                                                   hashId: playable.hashId,
                                                   playableUuid: playable.uuid,
                                                   playablePath: playable.path ?? nil,
                                                   playbackPosition: Double(0),
                                                   updatedAt: playable.updatedAt ?? nil,
                                                   uuid: UUID().uuidString,
                                                   insertedAt: playable.insertedAt,
                                                   largeThumbnailPath: playable.largeThumbnailPath ?? nil,
                                                   localizedname: playable.localizedname,
                                                   mediaCategory: playable.mediaCategory,
                                                   path: playablePath,
                                                   playlistUuid: playable.playlistUuid,
                                                   presenterName: playable.presenterName ?? nil,
                                                   smallThumbnailPath: playable.smallThumbnailPath ?? nil,
                                                   medThumbnailPath: playable.medThumbnailPath ?? nil,
                                                   sourceMaterial: playable.sourceMaterial ?? nil,
                                                   trackNumber: playable.trackNumber ?? nil)
                            try newAction.insert(db)
                        }
                        
                    }
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create { }
        }
        //        return Single.just(())
    }

    public func fetchPlayableHistory() -> Single<[Playable]> {
        return Single.create { [unowned self] single in
            do {
                var fetchPlayableHistory: [Playable] = []
                try self.dbPool.read { db in
                    let updatedAt = Column("updatedAt")
                    fetchPlayableHistory = try UserActionPlayable.order(updatedAt.desc).fetchAll(db)
                }
                single(.success(fetchPlayableHistory))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }

    public func fetchLastUserActionPlayableState(playableUuid: String) -> Single<UserActionPlayable?> {
        return Single.create { [unowned self] single in
            do {
                var playable: UserActionPlayable!
                
                try self.dbPool.read { db in
                    playable = try UserActionPlayable.filter(Column("playableUuid") == playableUuid).fetchOne(db)
                }
                single(.success(playable))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    // MARK: FileDownload
    
    public func updateFileDownloadHistory(fileDownload: FileDownload) -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    // update
                    DDLogDebug("try fileDownload update playable.uuid: \(fileDownload.uuid)")
                    if let download = try FileDownload.filter(Column("playableUuid") == fileDownload.playableUuid).fetchOne(db) {
                        // update existing download
                        var storeDownload: FileDownload = download
                        storeDownload.progress = fileDownload.progress
                        storeDownload.totalCount = fileDownload.totalCount
                        storeDownload.completedCount = fileDownload.completedCount
                        storeDownload.state = fileDownload.state
                        storeDownload.extendedDescription = fileDownload.extendedDescription
                        storeDownload.playlistUuid = fileDownload.playlistUuid
                        try storeDownload.update(db)
                        //                        }
                        
                    } else {
                        // insert new action
                        DDLogDebug("fileDownload not found, fileDownload.playableUuid: \(fileDownload.playableUuid)")
                        var newFileDownload: FileDownload =
                            FileDownload(url: fileDownload.url,
                                         uuid: fileDownload.uuid,
                                         playableUuid: fileDownload.playableUuid,
                                         localUrl: fileDownload.localUrl,
                                         updatedAt: fileDownload.updatedAt,
                                         insertedAt: fileDownload.insertedAt,
                                         progress: fileDownload.progress,
                                         totalCount: fileDownload.totalCount,
                                         completedCount: fileDownload.completedCount,
                                         state: fileDownload.state)
                        newFileDownload.extendedDescription = fileDownload.extendedDescription
                        newFileDownload.playlistUuid = fileDownload.playlistUuid

                        try newFileDownload.insert(db)
                        //                        }
                        
                    }
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create { }
        }
    }
    
    public func updateFileDownloads(playableUuids: [String], to state: FileDownloadState) -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    // update
//                    DDLogDebug("try fileDownload update playable.uuid: \(fileDownload.uuid)")
                    
//                    do {
                        try playableUuids.forEach({ uuid in
                            if let download = try FileDownload.filter(Column("playableUuid") == playableUuids[0]).fetchOne(db) {
                                // update existing download
                                
                                // db update
                                var storeDownload: FileDownload = download
                                //                        storeDownload.progress = fileDownload.progress
                                //                        storeDownload.totalCount = fileDownload.totalCount
                                //                        storeDownload.completedCount = fileDownload.completedCount
                                storeDownload.state = state
                                try storeDownload.update(db)
                                //                        }
                                
                            }
                        })
//                    } catch {
//                        DDLogDebug("error: \(error)")
//                        single(.error(error))
//                    }
                    
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create { }
        }
    }
    

    
    public func fetchLastFileDownloadHistory(playableUuid: String) -> Single<FileDownload?> {
        return Single.create { [unowned self] single in
            do {
                var playable: FileDownload!
                
                try self.dbPool.read { db in
                    playable = try FileDownload.filter(Column("playableUuid") == playableUuid).fetchOne(db)
                }
                single(.success(playable))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }

    public func deleteLastFileDownloadHistory(playableUuid: String) -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    //                    let selectBook = try db.makeSelectStatement("SELECT * FROM book WHERE bid = ?")
                    try FileDownload.filter(Column("playableUuid") == playableUuid).deleteAll(db)
                    return .commit
                }
                single(.success(()))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create()
        }
        //        return Single.just(())
    }
    
    public func deleteFileDownloadFile(playableUuid: String, pathExtension: String) -> Single<Void> {
        return Single.create { [unowned self] single in
            do {
                let url: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(playableUuid.appending(String(describing: ".\(pathExtension)"))).path)
                let fileManager = FileManager.default
                    do {
                        try fileManager.removeItem(atPath: url.path)
                    }
                    catch let error {
                        print("Ooops! Something went wrong removing file: \(error)")
                        throw error
                    }
                single(.success(()))
            } catch {
                single(.error(error))
            }
            return Disposables.create()
        }
    }
    
    public func fileDownloads(for playlistUuid: String) -> Single<[FileDownload]> {
        return Single.create { [unowned self] single in
            do {
                var fetchFileDownloads: [FileDownload] = []
                try self.dbPool.read { db in
                    fetchFileDownloads = try FileDownload.filter(Column("playlistUuid") == playlistUuid).fetchAll(db)
                }
                single(.success(fetchFileDownloads))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }

    public func fetchPlayables(for categoryUuid: String) -> Single<[Playable]> {
        return Single.create { [unowned self] single in
            do {
                var playables: [UserActionPlayable]!
                
                try self.dbPool.read { db in
                    let sql = """
                        SELECT
                            userActionPlayableId,
                            uuid,
                            playableUuid,
                            playablePath,
                            createdAt,
                            updatedAt,
                            playbackPosition,
                            downloaded,
                            categoryUuid,
                            localizedName,
                            path,
                            presenterName,
                            sourceMaterial,
                            trackNumber,
                            largeThumbnailPath,
                            smallThumbnailPath,
                        FROM
                            useractionplayable
                        LEFT JOIN book ON book.categoryUuid = userActionPlayableId.categoryUuid
                        LEFT JOIN gospel ON gospel.categoryUuid = userActionPlayableId.categoryUuid
                        LEFT JOIN music ON music.categoryUuid = userActionPlayableId.categoryUuid
                        """
                    playables = try UserActionPlayable.fetchAll(db, sql: sql)
                    DDLogDebug("playables: \(String(describing: playables))")
                }
                single(.success(playables))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
    }
}


