import Foundation
import Swinject
import Moya
//import BoseMobileCore
//import BoseMobileUI
//import BoseMobileCommunication
//import BoseMobilePresentation
//import BoseMobileModels
//import BoseMobileUtilities
//import BoseMobileData
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
    
    /// This is where you wire up the dependencies for the app!
    private static func applicationContainer() -> Container {
        // create a new container
        let container = Container()
        
        container.register(DataService.self) { resolver in
            return DataService(kjvrvgNetworking: MoyaProvider<KJVRVGService>())
        }.inObjectScope(.container)
        
        container.register(ProductServicing.self) { resolver in
            return ProductService(dataService: resolver.resolve(DataService.self)!)
            }.inObjectScope(.container)

//        container.register(GospelServicing.self) { resolver in
//            return GospelService(dataService: resolver.resolve(DataService.self)!)
//        }.inObjectScope(.container)
        
//        container.register(DataService.self) { resolver in
//            All_Scripture.DataService(kjvrvgNetworking: MoyaProvider<KJVRVGService>())
//            }.inObjectScope(.container)
        
//        container.register(GospelServicing.self) { resolver in
//            return GospelService(dataService: GospelDataServicing.self as! GospelDataServicing)
//            }.inObjectScope(.container)

        
//        container.register(GigyaBridging.self) { _ in
//            GigyaBridge()
//        }
        
        attachAppLevelDependencies(to: container)
        attachUtilityDependencies(to: container)
        
//        attachInitialFlowDependencies(to: container)
        attachMainFlowDependencies(to: container)
        attachSplashScreenFlowDependencies(to: container)
//        attachSettingsFlowDependencies(to: container)
//        attachAccountSetupDependencies(to: container)
        
        return container
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
//                accountService: resolver.resolve(AccountServicing.self)!,
                productService: resolver.resolve(ProductServicing.self)!
            )
        }

        container.register(AppUIMaking.self) { resolver in
            UIFactory(resolver: resolver)
        }
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
    
    private static func attachMainFlowDependencies(to container: Container) {
        container.register(MainCoordinator.self) { resolver in
            MainCoordinator(
                appUIMaking: resolver.resolve(AppUIMaking.self)!//,
//                resettableDeviceNowPlayingCoordinator: Resettable {
//                    resolver.resolve(DeviceNowPlayingCoordinator.self)!
//                },
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
//                deviceManager: resolver.resolve(DeviceManaging.self)!
            )
        }
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
    
    // MARK: Bose-mobile dependencies
    
    /// All bose-mobile related dependencies are assembled here.  Note that custom configurations can be specified per
    /// bose-module.
    private static func appModulesAssemblies() -> [Assembly] {
//        let boseCoreAssembly = BoseMobileCore.DependencyAssembly(with: nil)
//        let boseCommunicationAssembly = BoseMobileCommunication.DependencyAssembly(with: nil)
//        let bosePresentationAssembly = BoseMobilePresentation.DependencyAssembly(with: nil)
//        let boseUiAssembly = BoseMobileUI.DependencyAssembly(with: nil)
//        let boseDataAssembly = BoseMobileData.DependencyAssembly(with: nil)
//        return [boseCoreAssembly,
//                boseCommunicationAssembly,
//                bosePresentationAssembly,
//                boseUiAssembly,
//                boseDataAssembly]
        return []
    }
    
}
