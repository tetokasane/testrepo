//
//  ShortVideoScreenRouter.swift
//  wasd
//
//  Created by Глебов Алексей on 03.07.2023.
//

import UIKit
import Foundation
import Combine
import WSDNetwork

final class ShortVideoScreenRouter: RouterRepresentable {
    
    // MARK: - Instance Properties
    
    weak var managedScene: ShortVideoScreenViewController?
    
    var navigator: UINavigationController?
    
    var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Public properties
    
    var authService: AuthServiceProtocol?
    
    // MARK: - Init
    
    init() {}
    
    init(navigator: UINavigationController) {
        self.navigator = navigator
    }
    
    // MARK: - Instance Methods

    /// Переход на экран ввода поиска
    func routeToSearchInput() {
        let searchInputNavigationController = SearchInputRouter
            .newNavigation(
                rootViewType: SearchInputViewController.self,
                navigatorType: MainNavigationController.self
            )
        searchInputNavigationController.modalPresentationStyle = .overCurrentContext
        searchInputNavigationController.modalTransitionStyle = .crossDissolve
        managedScene?.present(searchInputNavigationController, animated: true)
    }
    
    /// Открыть профиль
    /// - Parameter channelId: id канала
    func openProfile(channelId: Int? = nil) {
            route(to: ProfileViewController.self,
                  animated: false,
                  setupView: nil,
                  setupViewModel: { viewModel in
                viewModel.channelId = channelId
                viewModel.networkHelper = ProfileNetworkHelper(serviceBuilder: AppAssembler.unsafeResolve(ServiceBuilderProtocol.self))
                viewModel.authService =  AppAssembler.unsafeResolve(AuthServiceProtocol.self)
            },
                  setupRouter: nil)
    }

    func openAuthScreen() {
        guard let navigator = self.navigator else { return }

        let modelBuilder = WSDNetwork.AuthModuleBuilder(
            environmentProvider: APISettings(),
            parentNavigation: navigator,
            output: self
        )
        modelBuilder.startAuth()
    }

    /// Открыть bottomSheet для жалоб и отписок
    /// - Parameters:
    ///   - complainLink: линка для жалобы
    ///   - channelName: имя канала
    func openSeeMoreBottomSheet(complainLink: String?, channelName: String?) {
        let bottomSheetController = BottomSheetContainerController(contentHeight: 160)
        let view = FeedbackView(frame: .zero, isOnlyComplain: true)
        view.setup(with: channelName ?? "")
        
        view.onComplainTapSubject.sink { [weak self] in
                guard let self else { return }
                
                bottomSheetController.close {
                    guard let urlString = complainLink,
                          let url = URL(string: urlString) else { return }

                    if self.authService?.isAuthorized == true {
                        self.openWebViewScreen(url: url)
                    } else {
                        self.openAuthScreen()
                    }
                }
            }.store(in: &subscriptions)

        bottomSheetController.set(contentView: view, insets: .zero)
        
        if let tabBar = managedScene?.tabBarController {
            bottomSheetController.addTo(controller: tabBar)
        }
        
        bottomSheetController.show()
    }
    
    func openShareActionScreen(url: String?) {
        guard let url else { return }
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        managedScene?.present(activityViewController, animated: true)
    }

    /// открыть вебвиью жалобы
    /// - Parameter url: url жалобы
    private func openWebViewScreen(url: URL) {
        let webView = CustomWebViewController()
        webView.customWebView.load(URLRequest(url: url))
        managedScene?.navigationController?.pushViewController(webView, animated: false)
    }
}

extension ShortVideoScreenRouter: AuthCoordinatorOutput {
    func userSuccessfullyLoggedIn() {}
}
