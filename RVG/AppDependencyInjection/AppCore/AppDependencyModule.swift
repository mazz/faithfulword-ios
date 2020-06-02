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
        container.register(LoginSequencer.self) { resolver in

            container.register(DataService.self) { resolver in
                return DataService(dataStore: DataStore(),
                                   networkingApi: MoyaProvider<FwbcApiService>(),
                                   reachability: resolver.resolve(RxClassicReachable.self)!)
                }.inObjectScope(.container)


            return LoginSequencer(dataService: resolver.resolve(DataService.self)!)
            }.inObjectScope(.container)

        container.register(ProductServicing.self) { resolver in
            return ProductService(dataService: resolver.resolve(DataService.self)!)
            }.inObjectScope(.container)

        container.register(SearchServicing.self) { resolver in
            return SearchService(dataService: resolver.resolve(DataService.self)!)
            }.inObjectScope(.container)

        container.register(LanguageServicing.self) { resolver in
            return LanguageService(dataService: resolver.resolve(DataService.self)!)
            }.inObjectScope(.container)

        container.register(AccountServicing.self) { resolver in
            return AccountService(loginSequencer: resolver.resolve(LoginSequencer.self)!,
                                  dataService: resolver.resolve(DataService.self)!)
            //            return ProductService(dataService: resolver.resolve(DataService.self)!)
            }.inObjectScope(.container)
        
        container.register(MediaRouteHandling.self) { _ in
            return MediaRouteHandler()
        }.inObjectScope(.container)

        container.register(MediaUniversalLinkHandling.self) { _ in
            return MediaUniversalLinkHandler()
        }.inObjectScope(.container)

        attachUtilityDependencies(to: container)
        attachAppLevelDependencies(to: container)
        attachSideMenuFlowDependencies(to: container)
        //        attachInitialFlowDependencies(to: container)
        attachAssetPlaybackDependencies(to: container)
        attachDownloadingDependencies(to: container)
        attachMainFlowDependencies(to: container)
        attachSplashScreenFlowDependencies(to: container)
        //        attachSettingsFlowDependencies(to: container)
        //        attachAccountSetupDependencies(to: container)

        return container
    }

    private static func attachUtilityDependencies(to container: Container) {
//        container.register(RxReachable.self) { _ in
//            RxReachability(
//                reachabilityManager: Alamofire.NetworkReachabilityManager(host: "www.apple.com")
//            )
//        }
        
        container.register(RxClassicReachable.self) { _ in
            RxClassicReachability(reachability: ClassicReachability(hostname: "www.apple.com"))
        }
    }

    private static func attachAppLevelDependencies(to container: Container) {
        container.register(AppInfoProviding.self) { _ in
            AppInfoProvider()
        }

        container.register(DeviceInfoProviding.self) { _ in
            DeviceInfoProvider()
        }

        container.register(AssetPlaybackManager.self) { resolver in
            AssetPlaybackManager()
            }.inObjectScope(.container)

        container.register(RemoteCommandManager.self) { resolver in
            RemoteCommandManager(assetPlaybackManager: resolver.resolve(AssetPlaybackManager.self)!)
            }.inObjectScope(.container)

        container.register(AssetPlaybackServicing.self) { resolver in
            AssetPlaybackService(assetPlaybackManager: resolver.resolve(AssetPlaybackManager.self)!, remoteCommandManager: resolver.resolve(RemoteCommandManager.self)!,
         reachability: resolver.resolve(RxClassicReachable.self)!
            )
            }.inObjectScope(.container)

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
                resettableNoResourceCoordinator: Resettable {
                    resolver.resolve(NoResourceCoordinator.self)!
                },
//                resettablePlaybackCoordinator: Resettable {
//                    resolver.resolve(PlaybackCoordinator.self)!
//                },
                //                resettableAccountSetupCoordinator: Resettable {
                //                    resolver.resolve(AccountSetupCoordinator.self)!
                //                },
                accountService: resolver.resolve(AccountServicing.self)!,
                productService: resolver.resolve(ProductServicing.self)!,
                languageService: resolver.resolve(LanguageServicing.self)!,
                assetPlaybackService: resolver.resolve(AssetPlaybackServicing.self)!,
                downloadService: resolver.resolve(DownloadServicing.self)!,
//                historyService: resolver.resolve(HistoryServicing.self)!,
                reachability: resolver.resolve(RxClassicReachable.self)!
            )
        }//.inObjectScope(.container)

        container.register(AppUIMaking.self) { resolver in
            UIFactory(resolver: resolver)
        }
    }

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

    private static func attachAssetPlaybackDependencies(to container: Container) {

        container.register(HistoryServicing.self) { resolver in
            return HistoryService(dataService: resolver.resolve(DataService.self)!)
            }.inObjectScope(.container)

        container.register(UserActionsServicing.self) { resolver in
            return UserActionsService(dataService: resolver.resolve(DataService.self)!)
            }.inObjectScope(.container)
        
        container.register(UserActionsViewModel.self) { resolver in
            UserActionsViewModel(userActionsService: resolver.resolve(UserActionsServicing.self)!,
                                 historyService:
                resolver.resolve(HistoryServicing.self)!
                //                assetPlaybackService: resolver.resolve(AssetPlaybackService.self)!
            )
            }.inObjectScope(.container)

        

        container.register(PlaybackControlsViewModel.self) { resolver in
            PlaybackControlsViewModel(assetPlaybackService: resolver.resolve(AssetPlaybackServicing.self)!,
                                      historyService: resolver.resolve(HistoryServicing.self)!,
                                      reachability: resolver.resolve(RxClassicReachable.self)!
//                assetPlaybackService: resolver.resolve(AssetPlaybackService.self)!
            )
        }.inObjectScope(.container)

        container.register(PlaybackCoordinator.self) { resolver in
            PlaybackCoordinator(uiFactory: resolver.resolve(AppUIMaking.self)!,
                                assetPlaybackService: resolver.resolve(AssetPlaybackServicing.self)!)
        }.inObjectScope(.container)
    }

    private static func attachDownloadingDependencies(to container: Container) {
//        container.register(FileDownloadServicing.self) { resolver in
//            return DownloadDataService(fileWebService: MoyaProvider<FileWebService>())
//            }.inObjectScope(.container)

        container.register(DownloadServicing.self) { resolver in
//            return DownloadService(downloadQueue: OperationQueue())
            return DownloadService(reachability: resolver.resolve(RxClassicReachable.self)!,
                                   dataService: resolver.resolve(DataService.self)!)
            }.inObjectScope(.container)
    }

    private static func attachMainFlowDependencies(to container: Container) {

        container.register(MediaRouteCoordinator.self) { resolver in
            MediaRouteCoordinator(uiFactory: resolver.resolve(AppUIMaking.self)!,
//                                  mediaRouteHandler: resolver.resolve(MediaRouteHandling.self)!,
                productService: resolver.resolve(ProductServicing.self)!,
                                  resettablePlaybackCoordinator: Resettable {
                resolver.resolve(PlaybackCoordinator.self)!
                }
            )
        }

        container.register(MediaListingCoordinator.self) { resolver in
            MediaListingCoordinator(uiFactory: resolver.resolve(AppUIMaking.self)!, resettablePlaybackCoordinator: Resettable {
                                        resolver.resolve(PlaybackCoordinator.self)!
                }, resettableMediaDetailsCoordinator: Resettable {
                    resolver.resolve(MediaDetailsCoordinator.self)!
                }
            )
        }
        
        container.register(MediaDetailsCoordinator.self) { resolver in
            MediaDetailsCoordinator(uiFactory: resolver.resolve(AppUIMaking.self)!, resettablePlaybackCoordinator: Resettable {
                resolver.resolve(PlaybackCoordinator.self)!
                }
            )
        }

//        container.register(CategoryListingCoordinator.self) { resolver in
//            CategoryListingCoordinator(uiFactory: resolver.resolve(AppUIMaking.self)!,
//                                       resettableMediaListingCoordinator: Resettable {
//                                        resolver.resolve(MediaListingCoordinator.self)!
//                }
//            )
//        }

        container.register(ChannelCoordinator.self) { resolver in
            ChannelCoordinator(uiFactory: resolver.resolve(AppUIMaking.self)!,
                                       resettableMediaListingCoordinator: Resettable {
                                        resolver.resolve(MediaListingCoordinator.self)!
                }
            )
        }

        container.register(BibleLanguageCoordinator.self) { resolver in
            BibleLanguageCoordinator(uiFactory: resolver.resolve(AppUIMaking.self)!,
                                     resettableNoResourceCoordinator: Resettable {
                                        resolver.resolve(NoResourceCoordinator.self)!
                },
                reachability: resolver.resolve(RxClassicReachable.self)!
            )
        }

        container.register(HistoryCoordinator.self) { resolver in
            HistoryCoordinator(uiFactory: resolver.resolve(AppUIMaking.self)!, resettablePlaybackCoordinator: Resettable {
                                    resolver.resolve(PlaybackCoordinator.self)!
            }
            )
        }

        container.register(NoResourceCoordinator.self) { resolver in
            NoResourceCoordinator(uiFactory: resolver.resolve(AppUIMaking.self)!
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
                resettableChannelCoordinator: Resettable {
                    resolver.resolve(ChannelCoordinator.self)!
                },
                resettableBibleLanguageCoordinator: Resettable {
                    resolver.resolve(BibleLanguageCoordinator.self)!
                }, resettableHistoryCoordinator: Resettable {
                    resolver.resolve(HistoryCoordinator.self)!
                }, resettableMediaRouteCoordinator: Resettable {
                    resolver.resolve(MediaRouteCoordinator.self)!
                }, resettablePlaybackCoordinator: Resettable {
                    resolver.resolve(PlaybackCoordinator.self)!
                },
                   resettableNoResourceCoordinator: Resettable {
                    resolver.resolve(NoResourceCoordinator.self)!
                },
                   reachability: resolver.resolve(RxClassicReachable.self)!,
                mediaRouteHandler: resolver.resolve(MediaRouteHandling.self)!,
                mediaUniversalLinkHandler: resolver.resolve(MediaUniversalLinkHandling.self)!,
                productService: resolver.resolve(ProductServicing.self)!,
                historyService: resolver.resolve(HistoryServicing.self)!
            )
        }.inObjectScope(.container)
        
        /**
         view models should be stored as transient, otherwise they will
         be effectively `cached` in the container. Setting them to .container
         will create odd side-effects where swinject will use the viewmodel
         in the container rather than make a new viewmodel when making a view controller
        */
        
        
        container.register(BooksViewModel.self) { resolver in
            BooksViewModel(
                productService: resolver.resolve(ProductServicing.self)!,
                languageService: resolver.resolve(LanguageServicing.self)!
            )
        }.inObjectScope(.transient)

        container.register(NoResourceViewModel.self) { resolver in
            NoResourceViewModel()
            }.inObjectScope(.transient)

        container.register(MediaListingViewModel.self) { resolver, playlistId, mediaCategory in
            MediaListingViewModel(
                playlistUuid: playlistId,
                mediaCategory: mediaCategory,
                productService: resolver.resolve(ProductServicing.self)!,
//                searchService: resolver.resolve(SearchServicing.self)!,
                assetPlaybackService: resolver.resolve(AssetPlaybackServicing.self)!,
                reachability: resolver.resolve(RxClassicReachable.self)!
            )
            }.inObjectScope(.transient)

        container.register(MediaSearchViewModel.self) { resolver, playlistId, mediaCategory in
            MediaSearchViewModel(
                playlistUuid: playlistId,
                mediaCategory: mediaCategory,
                searchService: resolver.resolve(SearchServicing.self)!,
                assetPlaybackService: resolver.resolve(AssetPlaybackServicing.self)!,
                reachability: resolver.resolve(RxClassicReachable.self)!
            )
            }.inObjectScope(.transient)

        container.register(MediaDetailsViewModel.self) { resolver, playable in
            MediaDetailsViewModel(
                playable: playable,
                assetPlaybackService: resolver.resolve(AssetPlaybackServicing.self)!,
                reachability: resolver.resolve(RxClassicReachable.self)!
            )
            }.inObjectScope(.transient)

        container.register(CategoryListingViewModel.self) { resolver, categoryType in
            CategoryListingViewModel(
                categoryType: categoryType,
                productService: resolver.resolve(ProductServicing.self)!
            )
            }.inObjectScope(.transient)

        container.register(PlaylistViewModel.self) { resolver, channelUuid in
            PlaylistViewModel(
                channelUuid: channelUuid,
                productService: resolver.resolve(ProductServicing.self)!,
                languageService: resolver.resolve(LanguageServicing.self)!,
                reachability: resolver.resolve(RxClassicReachable.self)!
            )
            }.inObjectScope(.transient)

        container.register(LanguageViewModel.self) { resolver in
            LanguageViewModel(
                productService: resolver.resolve(ProductServicing.self)!,
                languageService:
                resolver.resolve(LanguageServicing.self)!
            )
        }.inObjectScope(.transient)

        container.register(DownloadViewModel.self) { resolver in
            DownloadViewModel(downloadService: resolver.resolve(DownloadServicing.self)!)
            }.inObjectScope(.transient)

        container.register(DownloadListingViewModel.self) { resolver in
            DownloadListingViewModel(downloadService: resolver.resolve(DownloadServicing.self)!)
            }.inObjectScope(.transient)
        
        container.register(HistoryPlaybackViewModel.self) { resolver in
            HistoryPlaybackViewModel(
                historyService: resolver.resolve(HistoryServicing.self)!,
                //                searchService: resolver.resolve(SearchServicing.self)!,
                assetPlaybackService: resolver.resolve(AssetPlaybackServicing.self)!,
                reachability: resolver.resolve(RxClassicReachable.self)!
            )
            }.inObjectScope(.container)

        container.register(HistoryDownloadViewModel.self) { resolver in
            HistoryDownloadViewModel(
                downloadService: resolver.resolve(DownloadServicing.self)!,
                //                searchService: resolver.resolve(SearchServicing.self)!,
                assetPlaybackService: resolver.resolve(AssetPlaybackServicing.self)!,
                reachability: resolver.resolve(RxClassicReachable.self)!
            )
            }.inObjectScope(.container)        
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
