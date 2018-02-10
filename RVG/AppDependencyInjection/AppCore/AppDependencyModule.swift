import Foundation
import Swinject
import Moya
import Alamofire

/// Central place for all app dependency wiring
internal final class AppDependencyModule {

    /// Use this resolver to grab dependencies
    internal var resolver: Resolver {
        return completeAssembler.resolver
    }
    private let completeAssembler: Assembler

    internal init() {
        Container.loggingFunction = nil
        completeAssembler = Assembler(container: AppDependencyModule.applicationContainer()
        )
    }

    // MARK: App-specific dependencies

    // MARK: ### Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value
    // MARK: ### did you remember to register the dependency before using it??

    /// This is where you wire up the dependencies for the app!
    private static func applicationContainer() -> Container {
        // create a new container
        let container = Container()

        //        container.register(DataStoring.self) { resolver in
        //            return DataStore()
        //        }
        //

        container.register(LoginSequencer.self) { resolver in


            container.register(DataService.self) { resolver in
                return DataService(dataStore: DataStore(),
                                   kjvrvgNetworking: MoyaProvider<KJVRVGService>(),
                                   reachability: resolver.resolve(RxReachable.self)!)
            }.inObjectScope(.container)


            return LoginSequencer(dataService: resolver.resolve(DataService.self)!)


            //            return DataService(dataStore: DataStore(),
            //                               kjvrvgNetworking: MoyaProvider<KJVRVGService>(),
            //                               reachability: resolver.resolve(RxReachable.self)!)
        }.inObjectScope(.container)



        container.register(ProductServicing.self) { resolver in
            return ProductService(dataService: resolver.resolve(DataService.self)!)
        }.inObjectScope(.container)

        container.register(AccountServicing.self) { resolver in
            return AccountService(loginSequencer: resolver.resolve(LoginSequencer.self)!,
                                  dataService: resolver.resolve(DataService.self)!)
            //            return ProductService(dataService: resolver.resolve(DataService.self)!)
        }.inObjectScope(.container)

        attachUtilityDependencies(to: container)
        attachAppLevelDependencies(to: container)
        attachSideMenuFlowDependencies(to: container)
        //        attachInitialFlowDependencies(to: container)
        attachMainFlowDependencies(to: container)
        attachSplashScreenFlowDependencies(to: container)
        //        attachSettingsFlowDependencies(to: container)
        //        attachAccountSetupDependencies(to: container)

        return container
    }

    private static func attachUtilityDependencies(to container: Container) {
        container.register(RxReachable.self) { _ in
            RxReachability(
                reachabilityManager: Alamofire.NetworkReachabilityManager(host: "www.apple.com")
            )
        }
        //        container.register(Analytics.self) { _ in
        //            Analytics()
        //        }
    }

    private static func attachAppLevelDependencies(to container: Container) {
        container.register(AppInfoProviding.self) { _ in
            AppInfoProvider()
        }


        container.register(AppCoordinator.self) { resolver in
            AppCoordinator(
                uiFactory: resolver.resolve(AppUIMaking.self)!,
                //                resettableInitialCoordinator: Resettable {
                //                    resolver.resolve(InitialCoordinator.self)!
                //                },
                resettableMainCoordinator: Resettable {
                    resolver.resolve(MainCoordinator.self)!
                },
                resettableSplashScreenCoordinator: Resettable {
                    resolver.resolve(SplashScreenCoordinator.self)!
                },
                //                resettableAccountSetupCoordinator: Resettable {
                //                    resolver.resolve(AccountSetupCoordinator.self)!
                //                },
                accountService: resolver.resolve(AccountServicing.self)!,
                productService: resolver.resolve(ProductServicing.self)!
            )
        }

        container.register(AppUIMaking.self) { resolver in
            UIFactory(resolver: resolver)
        }
    }


    //    private static func attachInitialFlowDependencies(to container: Container) {
    //        container.register(InitialCoordinator.self) { resolver in
    //            InitialCoordinator(
    //                uiFactory: resolver.resolve(AppUIMaking.self)!,
    //                resettableAuthCoordinator: Resettable {
    //                    resolver.resolve(AuthCoordinator.self)!
    //                }
    //            )
    //        }
    //    }

    private static func attachSideMenuFlowDependencies(to container: Container) {
        container.register(SideMenuCoordinator.self) { resolver in
            SideMenuCoordinator(
                uiFactory: resolver.resolve(AppUIMaking.self)!
            )
        }
        container.register(SideMenuViewModel.self) { resolver in
            SideMenuViewModel()
        }
    }


    private static func attachMainFlowDependencies(to container: Container) {
        container.register(MediaListingCoordinator.self) { resolver in
            MediaListingCoordinator(uiFactory: resolver.resolve(AppUIMaking.self)!)
        }

        container.register(CategoryListingCoordinator.self) { resolver in
            CategoryListingCoordinator(uiFactory: resolver.resolve(AppUIMaking.self)!,
                                       resettableMediaListingCoordinator: Resettable {
                                        resolver.resolve(MediaListingCoordinator.self)!
                }
//                                       resettableMediaListingCoordinator:resolver.resolve(MediaListingCoordinator.self)!
            )
        }

        container.register(MainCoordinator.self) { resolver in
            MainCoordinator(
                appUIMaking: resolver.resolve(AppUIMaking.self)!,
                resettableMediaListingCoordinator: Resettable {
                    resolver.resolve(MediaListingCoordinator.self)!
                },
                resettableSideMenuCoordinator: Resettable {
                    resolver.resolve(SideMenuCoordinator.self)!
                },
                resettableCategoryListingCoordinator: Resettable {
                    resolver.resolve(CategoryListingCoordinator.self)!
                }

                //                resettableSettingsCoordinator: Resettable {
                //                    resolver.resolve(SettingsCoordinator.self)!
                //                },
                //                resettableDeviceSelectionCoordinator: Resettable {
                //                    resolver.resolve(DeviceSelectionCoordinator.self)!
                //                },
                //                resettableSectionalNavigatorCoordinator: Resettable {
                //                    resolver.resolve(SectionalNavigatorCoordinator.self)!
                //                },
                //                resettableControlCentreCoordinator: Resettable {
                //                    resolver.resolve(ControlCentreCoordinator.self)!
                //                },
                //                deviceManager: resolver.resolve(DeviceManaging.self)!
            )
        }
        container.register(MainViewModel.self) { resolver in
            MainViewModel(
                productService: resolver.resolve(ProductServicing.self)!)
        }
        container.register(MediaListingViewModel.self) { resolver, playlistId, mediaType in
            MediaListingViewModel(
                playlistId: playlistId,
                mediaType: mediaType,
                productService: resolver.resolve(ProductServicing.self)!
            )
        }.inObjectScope(.transient)
        container.register(CategoryListingViewModel.self) { resolver, categoryType in
            CategoryListingViewModel(
                categoryType: categoryType,
                productService: resolver.resolve(ProductServicing.self)!
            )
        }.inObjectScope(.transient)
    }

    private static func attachSplashScreenFlowDependencies(to container: Container) {
        container.register(SplashScreenCoordinator.self) { resolver in
            SplashScreenCoordinator(
                uiFactory: resolver.resolve(AppUIMaking.self)!
            )
        }
    }

    //    private static func attachSettingsFlowDependencies(to container: Container) {
    //        container.register(SettingsUIMaking.self) { resolver in
    //            UIFactory(resolver: resolver)
    //        }
    //        container.register(SettingsCoordinator.self) { resolver in
    //            SettingsCoordinator(
    //                settingsUIMaking: resolver.resolve(SettingsUIMaking.self)!,
    //                resettableAPSetupCoordinator: Resettable {
    //                    resolver.resolve(APSetupCoordinator.self)!
    //                },
    //                resettableDeviceSetupCoordinator: Resettable {
    //                    resolver.resolve(DeviceSetupCoordinator.self)!
    //                },
    //                resettableManageMusicServicesCoordinator: Resettable {
    //                    resolver.resolve(ManageMusicServicesCoordinator.self)!
    //                },
    //                accountService: resolver.resolve(AccountServicing.self)!
    //            )
    //        }
    //        container.register(SettingsViewModel.self) { resolver in
    //            SettingsViewModel(
    //                appInfoProviding: resolver.resolve(AppInfoProviding.self)!,
    //                accountService: resolver.resolve(AccountServicing.self)!
    //            )
    //        }
    //    }

    //    private static func attachAccountSetupDependencies(to container: Container) {
    //        container.register(AccountSetupCoordinator.self) { resolver in
    //            AccountSetupCoordinator(
    //                deviceDiscoveryCoordinator: Resettable {
    //                    resolver.resolve(DeviceDiscoveryCoordinator.self)!
    //                },
    //                addDeviceCoordinator: Resettable {
    //                    resolver.resolve(AddDeviceCoordinator.self)!
    //                },
    //                nameDeviceCoordinator: Resettable {
    //                    resolver.resolve(NameDeviceCoordinator.self)!
    //                },
    //                addMusicServiceProviderCoordinator: Resettable {
    //                    resolver.resolve(AddServiceCoordinator.self, argument: AddServiceContext.onboarding)!
    //                },
    //                fullScreenPromptFactory: resolver.resolve(FullScreenPromptUIMaking.self)!,
    //                musicServiceAggregator: resolver.resolve(MusicServiceAggregation.self)!
    //            )
    //        }
    //    }

    // MARK: gose-mobile dependencies

    /// All gose-mobile related dependencies are assembled here.  Note that custom configurations can be specified per
    /// gose-module.
    private static func appModulesAssemblies() -> [Assembly] {
        //        let goseCoreAssembly = GoseMobileCore.DependencyAssembly(with: nil)
        //        let goseCommunicationAssembly = GoseMobileCommunication.DependencyAssembly(with: nil)
        //        let gosePresentationAssembly = GoseMobilePresentation.DependencyAssembly(with: nil)
        //        let goseUiAssembly = GoseMobileUI.DependencyAssembly(with: nil)
        //        let goseDataAssembly = GoseMobileData.DependencyAssembly(with: nil)
        //        return [goseCoreAssembly,
        //                goseCommunicationAssembly,
        //                gosePresentationAssembly,
        //                goseUiAssembly,
        //                goseDataAssembly]
        return []
    }

}
