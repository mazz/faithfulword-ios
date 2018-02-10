import RxSwift
import GRDB

//private enum GoseDataStoreError: Swift.Error, LocalizedError {
//    case personNotFound
//
//    public var errorDescription: String? {
//        switch self {
//        case .personNotFound:
//            return "Data Store error - Gose Person not found"
//        }
//    }
//}


/// Factory for Realm with default config
//internal typealias RealmProvider = () -> Realm
//public typealias GoseSessionFactory = ( _ accessToken: String?,
//                                        _ tokenType: GoseSessionTokenType?,
//                                        _ expiresIn: Int?,
//                                        _ refreshToken: String?,
//                                        _ gosePersonId: String) -> GoseSession

/// Protocol for storing and retrieving data from Realm database
public protocol DataStoring {
    //    func latestCachedUser() -> Single<String?>
    
    func addUser(session: String) -> Single<String>
    
    /// Fetch a list of products associated to a gose person from Realm database, returns nil if gose person not found
    //    func fetchAccountDevices(gosePersonId: String) -> Single<[UserProduct]>
    
    func addBooks(books: [Book]) -> Single<[Book]>
    func fetchBooks() -> Single<[Book]>
    func deleteAllBooks() -> Single<Void>
    
    func addChapters(chapters: [Playable], for bookUuid: String) -> Single<[Playable]>
    func fetchChapters(for bookUuid: String) -> Single<[Playable]>
    func deleteChapters(for bookUuid: String) -> Single<Void>

    func addMediaGospel(mediaGospel: [Playable], for categoryUuid: String) -> Single<[Playable]>
    func fetchMediaGospel(for categoryUuid: String) -> Single<[Playable]>
    func deleteMediaGospel(for categoryUuid: String) -> Single<Void>

    func addCategory(categoryList: [Categorizable],
                     for categoryListType: CategoryListingType) -> Single<[Categorizable]>

    func deleteCategoryList(for categoryListingType: CategoryListingType) -> Single<Void>

    func fetchCategoryList(for categoryListingType: CategoryListingType) -> Single<[Categorizable]>

    /// Add or update a gose person to Realm database
    //    func addPerson(goseSession: GoseSession) -> Single<GoseSession>
    /// Delete gose persons from Realm database
    //    func deleteGosePerson() -> Single<Void>
}

/// Storage class holding reference to realm object
public final class DataStore {

    // MARK: Dependencies
    public var dbPool: DatabasePool {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
        let databasePath = documentsPath.appendingPathComponent("db.sqlite")
        print("databasePath: \(databasePath)")
        return try! openDatabase(atPath: databasePath)
    }
    
    /// The DatabaseMigrator that defines the database schema.
    // See https://github.com/groue/GRDB.swift/#migrations
    internal var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v2") { db in
            do {
                try db.create(table: "user") { userTable in
                    print("created: \(userTable)")
                    userTable.column("userId", .integer).primaryKey()
                    userTable.column("userUuid", .text)
                    userTable.column("name", .text)
                    userTable.column("session", .text)
                    userTable.column("pushNotifications", .boolean)
                }
            }
            catch {
                print("error making user table: \(error)")
            }

            do {
                try db.create(table: "book") { bookTable in
                    print("created: \(bookTable)")
                    bookTable.column("categoryUuid", .text).primaryKey()
                    bookTable.column("title", .text)
                    bookTable.column("languageId", .text)
                    bookTable.column("localizedTitle", .text)
                    bookTable.column("userId", .integer).references("user", onDelete: .cascade)
                }
            }
            catch {
                print("error making book table: \(error)")
            }

            do {
                try db.create(table: "mediachapter") { chapterTable in
                    print("created: \(chapterTable)")
                    //                chapterTable.column("chapterId", .integer).primaryKey()
                    chapterTable.column("uuid", .text).primaryKey()
                    chapterTable.column("localizedName", .text)
                    chapterTable.column("path", .text)
                    chapterTable.column("presenterName", .text)
                    chapterTable.column("sourceMaterial", .text)
                    chapterTable.column("categoryUuid", .text).references("book", onDelete: .cascade)
                }
            }
            catch {
                print("error making mediachapter table: \(error)")
            }

            do {
                try db.create(table: "gospel") { gospelTable in
                    print("created: \(gospelTable)")
                    gospelTable.column("categoryUuid", .text).primaryKey()
                    gospelTable.column("title", .text)
                    gospelTable.column("languageId", .text)
                    gospelTable.column("localizedTitle", .text)
                    gospelTable.column("userId", .integer).references("user", onDelete: .cascade)
                }
            }
            catch {
                print("error making gospel table: \(error)")
            }

            do {
                try db.create(table: "mediagospel") { gospelTable in
                    print("created: \(gospelTable)")
                    //                chapterTable.column("chapterId", .integer).primaryKey()
                    gospelTable.column("uuid", .text).primaryKey()
                    gospelTable.column("localizedName", .text)
                    gospelTable.column("path", .text)
                    gospelTable.column("presenterName", .text)
                    gospelTable.column("sourceMaterial", .text)
                    gospelTable.column("categoryUuid", .text).references("gospel", onDelete: .cascade)
                }
            }
            catch {
                print("error making mediagospel table: \(error)")
            }
        }
        return migrator
    }

    //    private let realm: RealmProvider
    //    public var dbQueue: DatabaseQueue {
    //        let documentDir: URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    //        let fileUrl = documentDir.appendingPathComponent("model").appendingPathExtension("sqlite")
    //        print("fileUrl.absoluteString: \(fileUrl.absoluteString)")
    //        let dbQueue: DatabaseQueue = try! DatabaseQueue(path: fileUrl.absoluteString)
    //        return dbQueue
    //    }
    
    //    internal init?() {
    //        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
    //        let databasePath = documentsPath.appendingPathComponent("db.sqlite")
    //        do {
    //            try openDatabase(atPath: databasePath)
    //        } catch {
    //            print("error making db pool, need to bail now: \(error)")
    //        }
    ////        self.dbPool = try openDatabase(atPath: databasePath)
    //        return nil
    //    }
    
    internal func openDatabase(atPath path: String) throws -> DatabasePool {
        // Connect to the database
        // See https://github.com/groue/GRDB.swift/#database-connections
        let dbPool = try DatabasePool(path: path)
        
        // Use DatabaseMigrator to define the database schema
        // See https://github.com/groue/GRDB.swift/#migrations
        try migrator.migrate(dbPool)
        
        return dbPool
    }

    //        try DatabaseQueue(path: "/path/to/database.sqlite")
    //    internal init(realm: @escaping RealmProvider) {
    //        self.realm = realm
    //    }
    
    //    private func getPersistedPerson(gosePersonId: String?) -> PersistedGosePerson? {
    //        let realmInstance = realm()
    //        let result: PersistedGosePerson?
    //        if let gosePersonId = gosePersonId {
    //            let gosePersonPredicate = NSPredicate(format: "personId = %@", "\(gosePersonId)")
    //            result = realmInstance.objects(PersistedGosePerson.self).filter(gosePersonPredicate).first
    //        } else {
    //            result = realmInstance.objects(PersistedGosePerson.self).first
    //        }
    //        return result
    //    }
    
    //    private func fetchGosePerson(gosePersonId: String?, goseSessionFactory: @escaping GoseSessionFactory) -> Single<GoseSession?> {
    //        let realmInstance = realm()
    //        return Single.create { [unowned self] single in
    //            // If ID != nil, fetch the current gose person as there will always be at most one persisted gose person
    //            if let person = gosePersonId != nil ? self.getPersistedPerson(gosePersonId: gosePersonId!) : realmInstance.objects(PersistedGosePerson.self).first {
    //                single(.success( goseSessionFactory(person.accessToken, GoseSessionTokenType(rawValue: person.tokenType ?? ""), person.expiresIn.value, person.refreshToken, person.personId) ))
    //            } else {
    //                single(.error(GoseDataStoreError.personNotFound))
    //            }
    //            return Disposables.create {}
    //        }
    //    }
}



// MARK: <DataStoring>
extension DataStore: DataStoring {

    //MARK: User

    //    public func latestCachedUser() -> Single<String?> {
    //        guard let goseUser = getPersistedPerson(gosePersonId: nil) else { return Single.just(nil) }
    //
    //        return Single.just(goseSessionFactory(goseUser.accessToken,
    //                                              GoseSessionTokenType(rawValue: goseUser.tokenType ?? ""),
    //                                              goseUser.expiresIn.value, goseUser.refreshToken,
    //                                              goseUser.personId))
    //
    //        return Single.just("")
    //    }

    public func addUser(session: String) -> Single<String> {
        return Single.create { [unowned self] single in
            var resultSession: String = session
            do {
                try self.dbPool.writeInTransaction { db in
                    if try User.fetchCount(db) == 0 {
                        var user = User(userId: nil,
                                        name: "john hancock",
                                        session: session,
                                        pushNotifications: false)
                        try user.insert(db)
                        resultSession = user.session
                    }
                    return .commit
                }
                single(.success(resultSession))
            } catch {
                print(error)
                single(.error(error))
            }
            return Disposables.create {}
        }
        //        return Single.just("")
    }

    //    public func fetchAccountDevices(gosePersonId: String) -> Single<[UserProduct]> {
    //        return Single.create { [unowned self] single in
    //            var associatedProducts: [UserProduct] = []
    //            let person = self.getPersistedPerson(gosePersonId: gosePersonId)
    //
    //            if person != nil {
    //                let products = person!.associatedProducts
    //                associatedProducts = products.map { product -> UserProduct in
    //                    let settings = ProductSettings(name: product.settings?.name)
    //                    return UserProduct(productId: product.productId, productType: product.productType, persons: [:], settings: settings)
    //                }
    //                single(.success(associatedProducts))
    //            } else {
    //                single(.error(GoseDataStoreError.personNotFound))
    //            }
    //            return Disposables.create {}
    //        }
    //    }

    //    public func deleteGosePerson() -> Single<Void> {
    //        let realmInstance = realm()
    //        return Single.create { single in
    //            let persons = realmInstance.objects(PersistedGosePerson.self)
    //
    //            do {
    //                try realmInstance.write {
    //                    realmInstance.delete(persons)
    //                }
    //            } catch let error {
    //                single(.error(error))
    //            }
    //
    //            single(.success(()))
    //
    //            return Disposables.create {}
    //        }
    //    }

    // MARK: Categories

    public func addCategory(categoryList: [Categorizable],
                            for categoryListType: CategoryListingType) -> Single<[Categorizable]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    if let user = try User.fetchOne(db) {
                        for category in categoryList {
                            print("category: \(category)")
                            switch categoryListType {

                            case .gospel:
                                print(".gospel")
                                var storeGospel: Gospel = category as! Gospel
                                storeGospel.userId = user.userId
                                try storeGospel.insert(db)
                            case .music:
                                print(".music")
                            case .churches:
                                print(".churches")
                            }
                        }
                    }
                    return .commit
                }
                single(.success(categoryList))
            } catch {
                print(error)
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
                        print(".gospel")
                        try Gospel.deleteAll(db)
                    case .music:
                        print(".music")
                    case .churches:
                        print(".churches")
                    }
                    return .commit
                }
                single(.success(()))
            } catch {
                print(error)
                single(.error(error))
            }
            return Disposables.create()
        }
    }

    public func fetchCategoryList(for categoryListingType: CategoryListingType) -> Single<[Categorizable]> {
        return Single.create { [unowned self] single in
            do {
                var categoryList: [Categorizable] = []
                try self.dbPool.read { db in
                    switch categoryListingType {
                    case .gospel:
                        categoryList = try Gospel.fetchAll(db)
                    case .music:
                        print(".music")
                    case .churches:
                        print(".churches")
                    }
                }
                single(.success(categoryList))
            } catch {
                print(error)
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
                        print("found chapter book: \(book)")
                        for chapter in chapters {
                            var mediaChapter = MediaChapter(uuid: chapter.uuid,
                                                            localizedName: chapter.localizedName,
                                                            path: chapter.path,
                                                            presenterName: chapter.presenterName,
                                                            sourceMaterial: chapter.sourceMaterial,
                                                            categoryUuid: book.categoryUuid)
                            try mediaChapter.insert(db)
                        }
                    }
                    return .commit
                }
                single(.success(chapters))
            } catch {
                print(error)
                single(.error(error))
            }
            return Disposables.create {}
        }

        //        return Single.just([])
    }

    public func fetchChapters(for bookUuid: String) -> Single<[Playable]> {
        return Single.create { [unowned self] single in
            do {

                var chapters: [Playable] = []
                //                let chapters: [Playable]!
                try self.dbPool.read { db in
                    chapters = try MediaChapter.filter(Column("categoryUuid") == bookUuid).fetchAll(db)
                }
                single(.success(chapters))
            } catch {
                print(error)
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
                print(error)
                single(.error(error))
            }
            return Disposables.create()
        }
        //        return Single.just(())
    }

    // Mark: MediaGospel

    public func addMediaGospel(mediaGospel: [Playable], for categoryUuid: String) -> Single<[Playable]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    //                    let statement = try db.makeSelectStatement("SELECT * FROM book WHERE bid = ?")
                    if let gospel = try Gospel.filter(Column("categoryUuid") == categoryUuid).fetchOne(db){
                        print("found gospel: \(gospel)")
                        for media in mediaGospel {
                            var mediaGospel = MediaGospel(uuid: media.uuid,
                                                          localizedName: media.localizedName,
                                                          path: media.path,
                                                          presenterName: media.presenterName,
                                                          sourceMaterial: media.sourceMaterial,
                                                          categoryUuid: gospel.categoryUuid)
                            try mediaGospel.insert(db)
                        }
                    }
                    return .commit
                }
                single(.success(mediaGospel))
            } catch {
                print(error)
                single(.error(error))
            }
            return Disposables.create {}
        }
    }

    public func fetchMediaGospel(for categoryUuid: String) -> Single<[Playable]> {
        return Single.create { [unowned self] single in
            do {

                var mediaGospel: [Playable] = []
                try self.dbPool.read { db in
                    mediaGospel = try MediaGospel.filter(Column("categoryUuid") == categoryUuid).fetchAll(db)
                }
                single(.success(mediaGospel))
            } catch {
                print(error)
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
                print(error)
                single(.error(error))
            }
            return Disposables.create()
        }
        //        return Single.just(())
    }

    // MARK: Books

    public func addBooks(books: [Book]) -> Single<[Book]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in
                    if let user = try User.fetchOne(db) {
                        for book in books {
                            print("book: \(book)")
                            //            try! self.dbQueue.inDatabase { db in
                            var storeBook: Book = book
                            storeBook.userId = user.userId
                            try storeBook.insert(db)
                        }
                    }
                    return .commit
                }
                single(.success(books))
            } catch {
                print(error)
                single(.error(error))
            }
            return Disposables.create {}
        }
    }

    public func fetchBooks() -> Single<[Book]> {
        return Single.create { [unowned self] single in
            do {
                var books: [Book] = []
                try self.dbPool.read { db in
                    books = try Book.fetchAll(db)
                }
                single(.success(books))
            } catch {
                print(error)
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
                print(error)
                single(.error(error))
            }
            return Disposables.create()
        }
    }
    
    
    
    // This should follow the pattern of returning the object it adds in case it gets sanitized or something.
    //    func addPerson(goseSession: GoseSession) -> Single<GoseSession> {
    //        let realmInstance = realm()
    //        return Single.create { [unowned self] single in
    //            do {
    //                let persistedPerson = self.getPersistedPerson(gosePersonId: goseSession.gosePersonId)
    //
    //                let persisted = PersistedGosePerson(session: goseSession)
    //
    //                try realmInstance.write {
    //                    if let persistedPerson = persistedPerson {
    //                        // If the person is already in the Realm database it won't be added
    //                        if !persisted.isEqual(persistedPerson) {
    //                            persistedPerson.personId = goseSession.gosePersonId
    //                            persistedPerson.accessToken = goseSession.accessToken
    //                            persistedPerson.refreshToken = goseSession.refreshToken
    //                            persistedPerson.expiresIn = RealmOptional<Int>(goseSession.expiresIn)
    //                            persistedPerson.associatedProducts = List<PersistedProduct>()
    //                        }
    //                    } else {
    //                        realmInstance.add(persisted)
    //                    }
    //                }
    //                single(.success(goseSession))
    //            } catch let error {
    //                GoseLog.error("add person error: \(error)")
    //                single(.error(error))
    //            }
    //            return Disposables.create {}
    //        }
    //    }
}
