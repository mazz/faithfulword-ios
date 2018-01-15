//import RealmSwift
import RxSwift
//import BoseMobileModels
//import BoseMobileUtilities

import GRDB

//private enum BoseDataStoreError: Swift.Error, LocalizedError {
//    case personNotFound
//
//    public var errorDescription: String? {
//        switch self {
//        case .personNotFound:
//            return "Data Store error - Bose Person not found"
//        }
//    }
//}


/// Factory for Realm with default config
//internal typealias RealmProvider = () -> Realm
//public typealias BoseSessionFactory = ( _ accessToken: String?,
//                                        _ tokenType: BoseSessionTokenType?,
//                                        _ expiresIn: Int?,
//                                        _ refreshToken: String?,
//                                        _ bosePersonId: String) -> BoseSession

/// Protocol for storing and retrieving data from Realm database
public protocol DataStoring {
    /// Fetch the cached bose person in Realm database
//    func latestCachedUser(boseSessionFactory: @escaping BoseSessionFactory) -> Single<BoseSession?>
    /// Fetch a list of products associated to a bose person from Realm database, returns nil if bose person not found
//    func fetchAccountDevices(bosePersonId: String) -> Single<[UserProduct]>
    
    /// Write a list of products to Realm database
    func addBooks(books: [Book]) -> Single<[Book]>
    
    func fetchBooks() -> Single<[Book]>
    
    func deleteAllBooks() -> Single<Void>
    
    /// Add or update a bose person to Realm database
//    func addPerson(boseSession: BoseSession) -> Single<BoseSession>
    /// Delete bose persons from Realm database
//    func deleteBosePerson() -> Single<Void>
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
        
        migrator.registerMigration("v1.2") { db in
            try! db.create(table: "book") { bookTable in
                print("created: \(bookTable)")
                bookTable.column("id", .integer).primaryKey()
                bookTable.column("bid", .text)
                bookTable.column("title", .text)
                bookTable.column("languageId", .text)
                bookTable.column("localizedTitle", .text)
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
    
//    private func getPersistedPerson(bosePersonId: String?) -> PersistedBosePerson? {
//        let realmInstance = realm()
//        let result: PersistedBosePerson?
//        if let bosePersonId = bosePersonId {
//            let bosePersonPredicate = NSPredicate(format: "personId = %@", "\(bosePersonId)")
//            result = realmInstance.objects(PersistedBosePerson.self).filter(bosePersonPredicate).first
//        } else {
//            result = realmInstance.objects(PersistedBosePerson.self).first
//        }
//        return result
//    }
    
//    private func fetchBosePerson(bosePersonId: String?, boseSessionFactory: @escaping BoseSessionFactory) -> Single<BoseSession?> {
//        let realmInstance = realm()
//        return Single.create { [unowned self] single in
//            // If ID != nil, fetch the current bose person as there will always be at most one persisted bose person
//            if let person = bosePersonId != nil ? self.getPersistedPerson(bosePersonId: bosePersonId!) : realmInstance.objects(PersistedBosePerson.self).first {
//                single(.success( boseSessionFactory(person.accessToken, BoseSessionTokenType(rawValue: person.tokenType ?? ""), person.expiresIn.value, person.refreshToken, person.personId) ))
//            } else {
//                single(.error(BoseDataStoreError.personNotFound))
//            }
//            return Disposables.create {}
//        }
//    }
}



// MARK: <DataStoring>
extension DataStore: DataStoring {
//    public func latestCachedUser(boseSessionFactory: @escaping BoseSessionFactory) -> Single<BoseSession?> {
//        guard let boseUser = getPersistedPerson(bosePersonId: nil) else { return Single.just(nil) }
//
//        return Single.just(boseSessionFactory(boseUser.accessToken,
//                                              BoseSessionTokenType(rawValue: boseUser.tokenType ?? ""),
//                                              boseUser.expiresIn.value, boseUser.refreshToken,
//                                              boseUser.personId))
//    }
    
//    public func fetchAccountDevices(bosePersonId: String) -> Single<[UserProduct]> {
//        return Single.create { [unowned self] single in
//            var associatedProducts: [UserProduct] = []
//            let person = self.getPersistedPerson(bosePersonId: bosePersonId)
//
//            if person != nil {
//                let products = person!.associatedProducts
//                associatedProducts = products.map { product -> UserProduct in
//                    let settings = ProductSettings(name: product.settings?.name)
//                    return UserProduct(productId: product.productId, productType: product.productType, persons: [:], settings: settings)
//                }
//                single(.success(associatedProducts))
//            } else {
//                single(.error(BoseDataStoreError.personNotFound))
//            }
//            return Disposables.create {}
//        }
//    }
    
//    public func deleteBosePerson() -> Single<Void> {
//        let realmInstance = realm()
//        return Single.create { single in
//            let persons = realmInstance.objects(PersistedBosePerson.self)
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
    
    public func addBooks(books: [Book]) -> Single<[Book]> {
        return Single.create { [unowned self] single in
            do {
                try self.dbPool.writeInTransaction { db in

                for book in books {
                    print("book: \(book)")
                    //            try! self.dbQueue.inDatabase { db in
                        var book = Book(id: nil,
                                        bid: book.bid,
                                        title: book.title,
                                        languageId: book.languageId,
                                        localizedTitle: book.localizedTitle)
                    try book.insert(db)
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
//    func addPerson(boseSession: BoseSession) -> Single<BoseSession> {
//        let realmInstance = realm()
//        return Single.create { [unowned self] single in
//            do {
//                let persistedPerson = self.getPersistedPerson(bosePersonId: boseSession.bosePersonId)
//
//                let persisted = PersistedBosePerson(session: boseSession)
//
//                try realmInstance.write {
//                    if let persistedPerson = persistedPerson {
//                        // If the person is already in the Realm database it won't be added
//                        if !persisted.isEqual(persistedPerson) {
//                            persistedPerson.personId = boseSession.bosePersonId
//                            persistedPerson.accessToken = boseSession.accessToken
//                            persistedPerson.refreshToken = boseSession.refreshToken
//                            persistedPerson.expiresIn = RealmOptional<Int>(boseSession.expiresIn)
//                            persistedPerson.associatedProducts = List<PersistedProduct>()
//                        }
//                    } else {
//                        realmInstance.add(persisted)
//                    }
//                }
//                single(.success(boseSession))
//            } catch let error {
//                BoseLog.error("add person error: \(error)")
//                single(.error(error))
//            }
//            return Disposables.create {}
//        }
//    }
}
