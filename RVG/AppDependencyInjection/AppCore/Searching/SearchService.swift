//
//  SearchService.swift
//  FaithfulWord
//
//  Created by Michael on 2019-08-29.
//  Copyright © 2019 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift

//public enum ProductsFoundState {
//    case noProductsRegistered
//    case findingProducts
//    case productsFound
//}
//
//public enum ProductServiceError: Error {
//    case resourceLoadFailed
//}

public protocol SearchServicing {
    
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
    
//    func persistedDefaultOrgs() -> Single<[Org]>
//    func fetchDefaultOrgs(offset: Int, limit: Int) -> Single<[Org]>
//    func deleteDefaultOrgs() -> Single<Void>
//
//    func persistedChannels(for orgUuid: String) -> Single<[Channel]>
//    func fetchChannels(for orgUuid: String, offset: Int, limit: Int) -> Single<[Channel]>
//    func deleteChannels() -> Single<Void>
//
//    func persistedPlaylists(for channelUuid: String) -> Single<[Playlist]>
//    func fetchPlaylists(for channelUuid: String,
//                        offset: Int,
//                        limit: Int,
//                        cacheDirective: CacheDirective) -> Single<(PlaylistResponse, [Playlist])>
//
//    func persistedMediaItems(for playlistUuid: String) -> Single<[MediaItem]>
//    func fetchMediaItems(for playlistUuid: String,
//                         offset: Int,
//                         limit: Int,
//                         cacheDirective: CacheDirective) -> Single<(MediaItemResponse, [MediaItem])>
//
//    /// List of products registered to the user's Passport account
//    var userBooks: Field<[Book]> { get }
//    var defaultOrgs: Field<[Org]> { get }
//    var channels: Field<[Channel]> { get }
//    //    var userChapters: Field<[Playable]> { get }
//    //    var persistedUserBooks: Field<[Book]> { get }
//
//    func fetchBooks(stride: Int) -> Single<Void>
//
//    func deleteBooks() -> Single<Void>
//
//    func fetchChapters(for bookUuid: String, stride: Int) -> Single<[Playable]>
//    func fetchMediaGospel(for categoryUuid: String, stride: Int) -> Single<[Playable]>
//    func fetchMediaMusic(for categoryUuid: String, stride: Int) -> Single<[Playable]>
//    func fetchBibleLanguages(stride: Int) -> Single<[LanguageIdentifier]>
//
//    func fetchCategoryListing(for categoryType: CategoryListingType, stride: Int) -> Single<[Categorizable]>
}

public final class SearchService {
    
//    public let userBooks: Field<[Book]>
//    public let defaultOrgs: Field<[Org]>
//    public let channels: Field<[Channel]>
    //    public var userChapters: Field<[Playable]>
    
    //    public let persistedUserBooks: Field<[Book]>
    
    // MARK: Dependencies & instantiation
    private let dataService: SearchDataServicing
    
    private var bag = DisposeBag()
    
    public init(dataService: SearchDataServicing) {
        self.dataService = dataService
//        userBooks = Field(value: [], observable: dataService.books)
//        defaultOrgs = Field(value: [], observable: dataService.orgs)
//        channels = Field(value: [], observable: dataService.channels)
        //        userChapters = Field(value: [], observable: dataService.chapters)
        //        persistedUserBooks = Field(value: [], observable: dataService.persistedBooks)
    }
}

// MARK: <ProductServicing>
extension SearchService: SearchServicing {
    
//    public func persistedMediaItems(for playlistUuid: String) -> Single<[MediaItem]> {
//        return dataService.persistedMediaItems(for: playlistUuid)
//    }
//
    
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
        return dataService.searchMediaItems(query: query,
                                            mediaCategory: mediaCategory,
                                            playlistUuid: playlistUuid,
                                            channelUuid: channelUuid,
                                            publishedAfter: publishedAfter,
                                            updatedAfter: updatedAfter,
                                            presentedAfter: presentedAfter,
                                            offset: offset,
                                            limit: limit,
                                            cacheDirective: cacheDirective)

    }
//
//
//    public func persistedPlaylists(for channelUuid: String) -> Single<[Playlist]> {
//        return dataService.persistedPlaylists(for: channelUuid)
//    }
//
//    public func fetchPlaylists(for channelUuid: String,
//                               offset: Int,
//                               limit: Int,
//                               cacheDirective: CacheDirective) -> Single<(PlaylistResponse, [Playlist])> {
//        return dataService.fetchAndObservePlaylists(for: channelUuid,
//                                                    offset: offset,
//                                                    limit: limit,
//                                                    cacheDirective: cacheDirective)
//    }
//
//    public func persistedChannels(for orgUuid: String) -> Single<[Channel]> {
//        return dataService.persistedChannels(for: orgUuid)
//    }
//
//    public func fetchChannels(for orgUuid: String, offset: Int, limit: Int) -> Single<[Channel]> {
//        return dataService.fetchAndObserveChannels(for: orgUuid, offset: offset, limit: limit)
//    }
//
//    public func deleteChannels() -> Single<Void> {
//        return dataService.deletePersistedChannels()
//    }
//
//    public func persistedDefaultOrgs() -> Single<[Org]> {
//        return dataService.persistedDefaultOrgs()
//    }
//
//    public func fetchDefaultOrgs(offset: Int, limit: Int) -> Single<[Org]> {
//        return dataService.fetchAndObserveDefaultOrgs(offset: offset, limit: limit)
//    }
//
//    public func deleteDefaultOrgs() -> Single<Void> {
//        return dataService.deletePersistedDefaultOrgs()
//    }
//
//
//
//    public func fetchChapters(for bookUuid: String, stride: Int) -> Single<[Playable]> {
//        return dataService.chapters(for: bookUuid, stride: stride)
//    }
//
//    public func fetchMediaGospel(for categoryUuid: String, stride: Int) -> Single<[Playable]> {
//        return dataService.mediaGospel(for: categoryUuid, stride: stride)
//    }
//
//    public func fetchMediaMusic(for categoryUuid: String, stride: Int) -> Single<[Playable]> {
//        return dataService.mediaMusic(for: categoryUuid, stride: stride)
//    }
//
//    public func fetchBibleLanguages(stride: Int) -> Single<[LanguageIdentifier]> {
//        return dataService.bibleLanguages(stride: stride)
//    }
//
//    public func fetchBooks(stride: Int) -> Single<Void> {
//        return dataService.fetchAndObserveBooks(stride: stride).toVoid()
//    }
//
//    public func deleteBooks() -> Single<Void> {
//        return dataService.deletePersistedBooks()
//    }
//
//    public func fetchCategoryListing(for categoryType: CategoryListingType, stride: Int) -> Single<[Categorizable]> {
//        return dataService.categoryListing(for: categoryType, stride: stride)
//    }
    //func fetchChapters(for bookUuid: String) -> Single<[Playable]>
}
