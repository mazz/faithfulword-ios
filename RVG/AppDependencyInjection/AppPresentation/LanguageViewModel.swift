//
//  LanguageViewModel.swift
//  FaithfulWord
//
//  Created by Michael on 2018-02-16.
//  Copyright © 2018 KJVRVG. All rights reserved.
//

import Foundation
import RxSwift
import L10n_swift

internal final class LanguageViewModel: RadioListViewModeling {
//    public func section(at index: Int) -> RadioListSectionViewModel {
//        return internalSections.value[index]
//    }

    public func section(at index: Int) -> RadioListSectionViewModel {
        return datasource.value[index].section
    }

    // MARK: Fields
    private let bag =  DisposeBag()

    public var selectionEvent = PublishSubject<IndexPath>()
    public var title: Observable<String> {
        return Observable.just(NSLocalizedString("Set Bible Language", comment: "").l10n())
    }

    public var errorEvent = PublishSubject<Error>()
    public var fetchAppendItems: PublishSubject = PublishSubject<Bool>()

    private var internalSections = Field<[RadioListSectionViewModel]>([])

    private var datasource = Field<[(section: RadioListSectionViewModel, languageIdentifiers: [String])]>([])


    public var sections: Observable<[RadioListSectionViewModel]> {
        //        return datasource.asObservable()
        return datasource.asObservable().map { fullSections in
            fullSections.map { $0.section }
        }
    }

//    public func item(at indexPath: IndexPath) -> RadioListItemType {
//        return internalSections.value[indexPath.section].items[indexPath.item]
//    }

    public func item(at indexPath: IndexPath) -> RadioListItemType {
        return datasource.value[indexPath.section].section.items[indexPath.item]
    }

    public func fetchMoreItems() {
        fetchLanguages(stride: 100)
    }

    // MARK: Dependencies

    private let productService: ProductServicing
    private let languageService: LanguageServicing

    internal init(productService: ProductServicing,
                  languageService: LanguageServicing) {
        self.productService = productService
        self.languageService = languageService

        setupDatasource()
        setupSelection()
    }

    // MARK: Private helpers

    private func setupDatasource() {
        productService.fetchBibleLanguages(stride: 100).asObservable()
            .map { $0.map {
                (RadioListItemType.selectable(header: String("\($0.source_material) (\(self.localizedString(identifier: $0.language_identifier))) "), isSelected: false), $0.language_identifier)
                }
            }
            .next({ tuples in
                let listItems = tuples.map { $0.0 }
                let identifiers = tuples.map { $0.1 }

                self.datasource.value = [(section: RadioListSectionViewModel(type: .list, items: listItems), languageIdentifiers: identifiers)]
            })
            .disposed(by: bag)
        
        fetchAppendItems.asObservable()
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .next { [unowned self] _ in
                self.fetchMoreItems()
            }.disposed(by: bag)

    }

    func setupSelection() {
        self.selectionEvent.next { [unowned self] event in
            let identifier: String = self.datasource.value[event.section].languageIdentifiers[event.row]
            L10n.shared.language = identifier
//            self.languageService.swappedUserLanguage.value = identifier
            
            let deleted: Single<Void> = self.productService.deletePlaylists()
            
            deleted.flatMap { _ -> Single<String> in
                return self.languageService.updateUserLanguage(languageIdentifier: identifier)
            }
            .asObservable()
            .subscribeAndDispose(by: self.bag)
//                .asObservable()
//                .subscribeAndDispose(by: self.bag)

//                .flatMap { _ -> Single<String> in
//                return "test"
//            }
            
            
//            self.languageService.updateUserLanguage(languageIdentifier: identifier)
//                .asObservable()
//                .subscribe(onNext: { string in
//
//                }).disposed(by: self.bag)
            
            }.disposed(by: bag)
    }

    private func localizedString(identifier: String) -> String {
        let languageID = Bundle.main.preferredLocalizations[0]// [[NSBundle mainBundle] preferredLocalizations].firstObject;
        let locale = NSLocale(localeIdentifier: languageID)
        return locale.displayName(forKey: NSLocale.Key.identifier, value: identifier)!
    }
    
    func fetchLanguages(stride: Int) {
        productService.fetchBibleLanguages(stride: stride).asObservable()
            .subscribeAndDispose(by: self.bag)
    }
}
