import Foundation
import RxSwift
import L10n_swift

internal final class BibleLanguageViewModel {
    // MARK: Fields

    public func section(at index: Int) -> BibleLanguageSectionViewModel {
        return sections.value[index]
    }

    public func item(at indexPath: IndexPath) -> BibleLanguageItemType {
        return section(at: indexPath.section).items[indexPath.item]
    }

    public private(set) var sections = Field<[BibleLanguageSectionViewModel]>([])
    public let selectItemEvent = PublishSubject<IndexPath>()

    public var chooseLanguageEvent: Observable<BibleLanguageLanguageType> {
        // Emit events by mapping a tapped index path to setting-option.
        return self.selectItemEvent.filterMap { [unowned self] indexPath -> BibleLanguageLanguageType? in
            let section = self.sections.value[indexPath.section]
            let item = section.items[indexPath.item]
            // Don't emit an event for anything that is not a 'drillIn'
            if case .language(let type, _, let languageIdentifier, _, _) = item {

                self.languageService.updateUserLanguage(languageIdentifier: languageIdentifier)
                    .asObservable()
                    .subscribeAndDispose(by: self.bag)
                return type
            }
            return nil
        }
    }

    // MARK: Events

    public var selectionEvent = PublishSubject<IndexPath>()
    public var errorEvent = PublishSubject<Error>()

    // MARK: Dependencies

    private let productService: ProductServicing
    private let languageService: LanguageServicing

    private var bag = DisposeBag()

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
            .map { $0.map { BibleLanguageItemType.language(type: .defaultLanguageType(languageIdentifier: $0.languageIdentifier),
                                                           sourceMaterial: $0.sourceMaterial,
                                                           languageIdentifier: $0.languageIdentifier,
                                                           supported: $0.supported,
                                                           isSelected: L10n.shared.language == $0.languageIdentifier
                ) }
            }
            .next { [unowned self] languageIdentifiers in
                self.sections.value = [
                    BibleLanguageSectionViewModel(type: .languages, items: languageIdentifiers)
                ]
            }.disposed(by: bag)
    }

    private func setupSelection() {
        selectionEvent.next { [unowned self] indexPath in
            print("indexPath: \(indexPath)")
//            self.selectionBag = DisposeBag()
//            let voiceLanguage = self.datasource.value[indexPath.section].languages[indexPath.item]
//            self.device.execute(AssignVoiceLanguage(voiceLanguage)).subscribeAndDispose(by: self.selectionBag)
            }.disposed(by: bag)
    }

}


