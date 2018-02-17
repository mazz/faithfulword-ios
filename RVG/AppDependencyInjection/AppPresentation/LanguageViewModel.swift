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
    public func section(at index: Int) -> RadioListSectionViewModel {
        return internalSections.value[index]
    }

    // MARK: Fields
    private let bag =  DisposeBag()

    //    var sections: Observable<[RadioListSectionViewModel]>

    public var selectionEvent = PublishSubject<IndexPath>()

    public var title: Observable<String> {
        return Observable.just(NSLocalizedString("Set Bible Language", comment: "").l10n())
    }

    public var errorEvent = PublishSubject<Error>()

    private var internalSections = Field<[RadioListSectionViewModel]>([])

    public var sections: Observable<[RadioListSectionViewModel]> {
        return internalSections.asObservable()
    }

    public func item(at indexPath: IndexPath) -> RadioListItemType {
        return internalSections.value[indexPath.section].items[indexPath.item]
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
        productService.fetchBibleLanguages().asObservable()
            .map { $0.map {
                RadioListItemType.selectable(header: String("\($0.sourceMaterial) (\(self.localizedString(identifier: $0.languageIdentifier))) "), isSelected: false)
//                BibleLanguageItemType.language(type: .defaultLanguageType(languageIdentifier: $0.languageIdentifier),
//                                                           sourceMaterial: $0.sourceMaterial,
//                                                           languageIdentifier: $0.languageIdentifier,
//                                                           supported: $0.supported,
//                                                           isSelected: L10n.shared.language == $0.languageIdentifier
//                )
                }
            }
            .next { [unowned self] languageIdentifiers in
                self.internalSections.value = [
                    RadioListSectionViewModel(type: .list, items: languageIdentifiers)
                ]
            }.disposed(by: bag)
    }

    func setupSelection() {
        self.selectionEvent.next { [unowned self] event in
            print("event: \(event)")

            print("self.internalSections: \(self.internalSections.value)")
            }.disposed(by: bag)
    }

    private func localizedString(identifier: String) -> String {
        let languageID = Bundle.main.preferredLocalizations[0]// [[NSBundle mainBundle] preferredLocalizations].firstObject;
        let locale = NSLocale(localeIdentifier: languageID)
        return locale.displayName(forKey: NSLocale.Key.identifier, value: identifier)!
    }
}
