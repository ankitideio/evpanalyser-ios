//
//  AppNavigator.swift
//  Evp Analyzer
//
//  Created by Rameez Hasan on 07/06/2022.
//

import UIKit

//struct AppNavigator {
//
//    func installRoot(into window: UIWindow) {
//        // controller create & setup
//
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let tabBarVC = storyboard.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
//
//        let navController = AppNavigationController(rootViewController: sideMenuController)
//        navController.navigationBar.isHidden = true
//
//        let remoteDataSource = UserRemoteDataStore()
//        let repository = UserRepository.init(remoteUserDataSource: remoteDataSource)
//        let service = UserService.init(userRepository: repository)
//        let sideMenuNavigator = MainSideMenuNavigator(navigationController: navController, slideVCReference: sideMenuController)
//        let sideMenuviewModel = MainSideMenuViewModel(service: service, navigator: sideMenuNavigator)
//
//        remoteDataSource.delegate = repository
//        repository.delegate = service
//
////        if let vcs = tabBarVC.viewControllers ,vcs.count > 0 {
////            for each in vcs {
////                if let navHome = each as? UINavigationController {
////                    if let controller = navHome.viewControllers.first as? HomeViewController {
////                        let homeviewModel = HomeViewModel(service: service, navigator: HomeNavigator(navigationController: navHome, slideVCReference: sideMenuController))
////                        homeviewModel.delegate = controller
////                        service.delegate = homeviewModel
////                        controller.viewModel = homeviewModel
////                        tabBarVC.delegate = controller
////                        controller.slideVCReference = sideMenuController
////                        controller.sideMenuReference = sideMenuTableViewController
////                    } else if let controller = navHome.viewControllers.first as? SearchViewController {
////                        let searchviewModel = SearchViewModel(service: service, navigator: SearchNavigator(navigationController: navHome, slideVCReference: sideMenuController))
////                        searchviewModel.delegate = controller
////                        controller.viewModel = searchviewModel
////                        controller.slideVCReference = sideMenuController
////                        controller.sideMenuReference = sideMenuTableViewController
////                    } else if let controller = navHome.viewControllers.first as? NewPostViewController {
////                        let newpostviewModel = NewPostViewModel(service: service, navigator: NewPostNavigator(navigationController: navHome, slideVCReference: sideMenuController))
////                        newpostviewModel.delegate = controller
////                        controller.viewModel = newpostviewModel
////                        controller.slideVCReference = sideMenuController
////                        controller.sideMenuReference = sideMenuTableViewController
////                    }else if let controller = navHome.viewControllers.first as? NetworkViewController {
////                        let networkviewModel = NetworkViewModel(service: service, navigator: NetworkNavigator(navigationController: navHome, slideVCReference: sideMenuController))
////                        networkviewModel.delegate = controller
////                        controller.viewModel = networkviewModel
////                        controller.slideVCReference = sideMenuController
////                        controller.sideMenuReference = sideMenuTableViewController
////                    }else if let controller = navHome.viewControllers.first as? MyProfileViewController {
////                        let myprofileviewModel = MyProfileViewModel(service: service, navigator: MyProfileNavigator(navigationController: navHome, slideVCReference: sideMenuController))
////                        myprofileviewModel.delegate = controller
////                        controller.viewModel = myprofileviewModel
////                        controller.slideVCReference = sideMenuController
////                        controller.sideMenuReference = sideMenuTableViewController
////                    }
////                }
////            }
////        }
//
//        window.rootViewController = navController
//    }
//}
