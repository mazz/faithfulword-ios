import RxSwift
import GRDB
import L10n_swift

/// Protocol for storing and retrieving data from Realm database
public protocol DataStoring {
    //    func latestCachedUser() -> Single<String?>
    
    func addUser(session: String) -> Single<String>
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
    
    func updatePlayableHistory(playable: Playable, position: Float) -> Single<Void>
    func fetchPlayableHistory() -> Single<[Playable]>
    func fetchLastState(playableUuid: String) -> Single<Playable>
    
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
                try db.create(table: "user") { userTable in
                    DDLogDebug("created: \(userTable)")
                    userTable.column("userId", .integer).primaryKey()
                    userTable.column("userUuid", .text)
                    userTable.column("name", .text)
                    userTable.column("session", .text)
                    userTable.column("pushNotifications", .boolean)
                    userTable.column("language", .text)
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
                    bookTable.column("userId", .integer).references("user", onDelete: .cascade)
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
                    gospelTable.column("userId", .integer).references("user", onDelete: .cascade)
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
                    musicTable.column("userId", .integer).references("user", onDelete: .cascade)
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
                    userActionPlayableTable.column("userActionPlayableId", .integer).primaryKey()
                    userActionPlayableTable.column("uuid", .text)
                    userActionPlayableTable.column("playableUuid", .text)
                    userActionPlayableTable.column("playablePath", .text)
                    userActionPlayableTable.column("createdAt", .double)
                    userActionPlayableTable.column("updatedAt", .double)
                    userActionPlayableTable.column("playbackPosition", .double)
                    userActionPlayableTable.column("downloaded", .boolean)

                    // Playable
                    userActionPlayableTable.column("categoryUuid", .text)
                    userActionPlayableTable.column("localizedName", .text)
                    userActionPlayableTable.column("path", .text)
                    userActionPlayableTable.column("presenterName", .text)
                    userActionPlayableTable.column("sourceMaterial", .text)
                    userActionPlayableTable.column("trackNumber", .integer)
                    userActionPlayableTable.column("largeThumbnailPath", .text)
                    userActionPlayableTable.column("smallThumbnailPath", .text)
                }
            }
            catch {
                DDLogDebug("error making useractionplayable table: \(error)")
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
    
    //MARK: User
    
    public func addUser(session: String) -> Single<String> {
        return Single.create { [unowned self] single in
            var resultSession: String = session
            do {
                try self.dbPool.writeInTransaction { db in
                    if try User.fetchCount(db) == 0 {
                        
                        var user = User(userId: nil, name: "john hancock", session: session, pushNotifications: false, language: L10n.shared.language)
                        try user.insert(db)
                        resultSession = user.session
                    }
                    return .commit
                }
                single(.success(resultSession))
            } catch {
                DDLogDebug("error: \(error)")
                single(.error(error))
            }
            return Disposables.create {}
        }
        //        return Single.just("")
    }
    
    // MARK: -- User Language
    
    public func updateUserLanguage(identifier: String) -> Single<String> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    if let user = try User.fetchOne(db) {
                        var storeUser: User = user
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
                    if let user = try User.fetchOne(db) {
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
                    if let user = try User.fetchOne(db) {
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
                    if let book = try Book.filter(Column("categoryUuid") == bookUuid).fetchOne(db){
                        DDLogDebug("found chapter book: \(book)")
                        for chapter in chapters {
                            var mediaChapter = MediaChapter(uuid: chapter.uuid,
                                                            localizedName: chapter.localizedName,
                                                            path: chapter.path,
                                                            presenterName: chapter.presenterName,
                                                            sourceMaterial: chapter.sourceMaterial,
                                                            categoryUuid: book.categoryUuid,
                                                            trackNumber: chapter.trackNumber,
                                                            createdAt: chapter.createdAt,
                                                            updatedAt: chapter.updatedAt,
                                                            largeThumbnailPath: chapter.largeThumbnailPath,
                                                            smallThumbnailPath: chapter.smallThumbnailPath
                            )
                            try mediaChapter.insert(db)
                        }
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
                        for media in mediaGospel {
                            var mediaGospel = MediaGospel(uuid: media.uuid,
                                                          localizedName: media.localizedName,
                                                          path: media.path,
                                                          presenterName: media.presenterName,
                                                          sourceMaterial: media.sourceMaterial,
                                                          categoryUuid: gospel.categoryUuid,
                                                          trackNumber: media.trackNumber,
                                                          createdAt: media.createdAt,
                                                          updatedAt: media.updatedAt,
                                                          largeThumbnailPath: media.largeThumbnailPath,
                                                          smallThumbnailPath: media.smallThumbnailPath
                            )
                            try mediaGospel.insert(db)
                        }
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
                        for media in mediaMusic {
                            var mediaMusic = MediaMusic(uuid: media.uuid,
                                                        localizedName: media.localizedName,
                                                        path: media.path,
                                                        presenterName: media.presenterName,
                                                        sourceMaterial: media.sourceMaterial,
                                                        categoryUuid: music.categoryUuid,
                                                        trackNumber: media.trackNumber,
                                                        createdAt: media.createdAt,
                                                        updatedAt: media.updatedAt,
                                                        largeThumbnailPath: media.largeThumbnailPath,
                                                        smallThumbnailPath: media.smallThumbnailPath
                            )
                            try mediaMusic.insert(db)
                        }
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
                    if let user = try User.fetchOne(db) {
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
    
    public func updatePlayableHistory(playable: Playable, position: Float) -> Single<Void> {
        // let update: Single<Void> =
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    // update
                    if let action = try UserActionPlayable.filter(Column("playableUuid") == playable.uuid).fetchOne(db) {
                        DDLogDebug("found action: \(action)")
                        
                        if let playablePath = playable.path,
                            let prodUrl: URL = URL(string: playablePath) {
                            let pathExtension: String = prodUrl.pathExtension
                            let fileUrl: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(playable.uuid.appending(String(describing: ".\(pathExtension)"))).path)
                            let downloaded: Bool = FileManager.default.fileExists(atPath: fileUrl.path)
                            DDLogDebug("file there update? \(downloaded)")
                            
                            // back up 5 seconds to help the user remember the context, unless < 0
                            var newPosition: Double = Double(position)
                            newPosition = newPosition - 5
                            if newPosition < Double(0) { newPosition = Double(0) }
                            
                            // db update
                            var storeAction: UserActionPlayable = action
                            storeAction.playbackPosition = Double(newPosition)
                            storeAction.updatedAt = Date().timeIntervalSince1970
                            storeAction.downloaded = downloaded
                            try storeAction.update(db)
                        }
                        
                    } else {
                        // insert
                        if let playablePath = playable.path,
                            let prodUrl: URL = URL(string: playablePath)
                        {
                            let pathExtension: String = prodUrl.pathExtension
                            let fileUrl: URL = URL(fileURLWithPath: FileSystem.savedDirectory.appendingPathComponent(playable.uuid.appending(String(describing: ".\(pathExtension)"))).path)
                            let downloaded: Bool = FileManager.default.fileExists(atPath: fileUrl.path)
                            DDLogDebug("file there insert? \(downloaded)")
                            
                            // back up 5 seconds to help the user remember the context, unless < 0
                            var newPosition: Double = Double(position)
                            newPosition = newPosition - 5
                            if newPosition < Double(0) { newPosition = Double(0) }

                            var newAction: UserActionPlayable = UserActionPlayable(userActionPlayableId: nil,
                                                                                   uuid: UUID().uuidString,
                                                                                   categoryUuid: playable.categoryUuid,
                                                                                   playableUuid: playable.uuid,
                                                                                   playablePath: playable.path ?? nil,
                                                                                   createdAt: Date().timeIntervalSince1970,
                                                                                   updatedAt: Date().timeIntervalSince1970,
                                                                                   playbackPosition: Double(newPosition),
                                                                                   downloaded: downloaded,
                                                                                   localizedName: playable.localizedName ?? nil,
                                                                                   path: playablePath,
                                                                                   presenterName: playable.presenterName ?? nil,
                                                                                   sourceMaterial: playable.sourceMaterial ?? nil,
                                                                                   trackNumber: playable.trackNumber ?? nil,
                                                                                   largeThumbnailPath: playable.largeThumbnailPath ?? nil,
                                                                                   smallThumbnailPath: playable.smallThumbnailPath ?? nil
                            )
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

    public func fetchLastState(playableUuid: String) -> Single<Playable> {
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
                    playables = try UserActionPlayable.fetchAll(db, sql)
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


