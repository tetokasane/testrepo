//
//  ShortVideoScreenViewModel.swift
//  wasd
//
//  Created by Глебов Алексей on 16.04.2023.
//

import Foundation
import Combine

protocol ShortVideoScreenViewModelInput: AnyObject {
    var navBarCollectionAction: PassthroughSubject<Void, Never> { get }
    var navBarItemSelectedAction: PassthroughSubject<Int, Never> { get }
    var loadVideosAction: PassthroughSubject<Void, Never> { get }
    var didStartRefreshing: PassthroughSubject<Void, Never> { get }
}

protocol ShortVideoScreenViewModelOutput: AnyObject {
    var cellModels: CurrentValueSubject<[ShortListCollectionCellViewModel], Never> { get }
    var currentNavItems: CurrentValueSubject<[WASDNavigationTitleItem], Never> { get }
    var currentItemIndex: CurrentValueSubject<Int, Never> { get }
    var didEndRefreshing: PassthroughSubject<Void, Never> { get }
}

struct ShortsModel {}

class ShortVideoScreenViewModel: ViewModelNoModelRepresentable {
    typealias Router = ShortVideoScreenRouter
    typealias Model = ShortsModel
    
    // MARK: - Public Properties
    
    var input: Input?
    var output: Output?
    var service: ServiceBuilderProtocol?
    var router: ShortVideoScreenRouter
    var offset: Int?
    var channelId: Int?
    var sortType: String?

    enum Input {
        case viewDidLoad
        case didStartRefreshing
        case didScrollToEnd
        case navBar(action: NavBarAction)
        
        enum NavBarAction {
            case tapCollection
            case tapSearch
            case selectItem(_ item: Int)
            case onBackTap
        }
    }
    
    enum Output {
        case updateData(model: [ShortListCollectionCellViewModel], appendingNew: Bool)
        case didEndRefreshing
    }
    
    // MARK: Input
    let navBarCollectionAction: PassthroughSubject<Void, Never> = .init()
    let navBarItemSelectedAction: PassthroughSubject<Int, Never> = .init()
    let loadVideosAction: PassthroughSubject<Void, Never> = .init()
    let didStartRefreshing: PassthroughSubject<Void, Never> = .init()
    
    // MARK: - Output
    
    let cellModels: CurrentValueSubject<[ShortListCollectionCellViewModel], Never> = .init([])
    let currentNavItems: CurrentValueSubject<[WASDNavigationTitleItem], Never> = .init([])
    let currentItemIndex: CurrentValueSubject<Int, Never> = .init(0)
    let didEndRefreshing: PassthroughSubject<Void, Never> = .init()
    
    
    // MARK: - Constants
    
    enum Constants {
        static let name = "GameMaster"
        static let description = "Душа моя озарена неземной радостью, как эти чудесные весенние утра, которыми я наслаждаюсь от всего сердца. Я совсем один и блаженствую в здешнем краю, словно созданном для таких, как я. Я так счастлив, мой друг, так упоен ощущением покоя, что искусс"
        static let previewImageLargeName = "large"
        static let previewImageMediumName = "medium"
        static let previewImageSmallName = "small"
        static let prodBaseUrl = "https://wasd.tv/"
    }
    
    // MARK: - Private properties
    
    private var subscriptions: Set<AnyCancellable> = .init([])
    private let outputSubject = PassthroughSubject<Output, Never>()
    private var networkHelper = ShortNetworkHelper(serviceBuilder: AppAssembler.unsafeResolve(ServiceBuilderProtocol.self))
    private var currentPage = 0

    private var isRefreshing: Bool = false
    private var didPullToEnd = false

    // MARK: - Initialization

    required init(router: Router) {
        self.router = router
    }

    // MARK: - Public Methods
    
    func transform(inputSubject: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        
        inputSubject.sink { [weak self] event in
            switch event {
            case .navBar(let action):
                switch action {
                case .tapSearch:
                    self?.router.routeToSearchInput()
                case .tapCollection:
                    // TODO: - Show collection screen
                    debugPrint("Implement and show collection screen")
                case .selectItem(_):
                    debugPrint("Implement items select")
                case .onBackTap:
                    self?.router.popScene()
                }
            case .viewDidLoad:
                self?.loadVideos(incPage: false)
            case .didStartRefreshing:
                self?.offset = nil
                self?.didPullToEnd = false
                self?.loadVideos(incPage: false)
            case .didScrollToEnd:
                if self?.isRefreshing ?? false {
                    return
                } else {
                    self?.loadVideos(incPage: true)
                }
            }
        }.store(in: &subscriptions)
        
        return outputSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Methods
        
    private func routeToMore(complainLink: String, model: ShortListCollectionCellViewModel?) {
        router.openSeeMoreBottomSheet(complainLink: complainLink, channelName: model?.panelViewModel.nameText ?? "")
    }
    
    private func routeToShareScreen(string: String?) {
        router.openShareActionScreen(url: string)
    }
    
    private func loadVideos(incPage: Bool) {
        guard !isRefreshing && !didPullToEnd else {
            return
        }
        Task {
            do {
                self.isRefreshing = true
                
                if incPage {
                    if var offset = offset {
                        offset += cellModels.value.count
                    } else {
                        offset = cellModels.value.count
                    }
                }

                var subscriptionsModel: SubscriptionsModel?
                let shorts = try await self.networkHelper.getShorts(sortType: sortType, channelId: channelId, offset: offset)
                if self.router.authService?.isAuthorized == true {
                    subscriptionsModel = try await self.networkHelper.getSubscriptions()
                }

                bindCellModels(media: shorts, subscription: subscriptionsModel, incPage)
                self.isRefreshing = false
            } catch let error {
                debugPrint("error: \(error.localizedDescription)")
            }
            self.isRefreshing = false
        }
    }
    
    private func bindCellModels(media: MediaContainerArrayModel?, subscription: SubscriptionsModel?, _ incPage: Bool = false) {
        var models = [ShortListCollectionCellViewModel]()
        
        guard let media else { return }
        for shortMedia in media.result {
            let mediaMeta = shortMedia.mediaContainerStreams?.first?.streamMedia?.first?.mediaMeta
            let mediaUrlString =
            mediaMeta?.mediaPreviewArchiveImages?.large ??
            mediaMeta?.mediaPreviewArchiveImages?.medium ??
            mediaMeta?.mediaPreviewArchiveImages?.small ?? ""
            let previewImageUrl = URL(string: mediaUrlString)
            let id = shortMedia.mediaContainerId
            let channelId = shortMedia.channelId
            self.channelId = channelId
            let panelViewModel = ShortVideoScreenPanelsViewModelImpl()
            panelViewModel.descriptionText = shortMedia.mediaContainerName
            panelViewModel.nameText = shortMedia.mediaContainerUser?.userLogin
            
            panelViewModel.avatarImageUrl = URL(
                string: shortMedia.mediaContainerUser?.profileImage?.medium ??
                shortMedia.mediaContainerUser?.profileImage?.small ?? ""
            )
            
            panelViewModel.moreAction.sink { [unowned self] cellModel in
                let complainLink = makeComplainString(model: shortMedia)
                self.routeToMore(complainLink: complainLink, model: cellModel)
            }.store(in: &subscriptions)
            
            panelViewModel.shareAction.sink { [unowned self] _ in
                guard let name = shortMedia.mediaContainerUser?.userLogin, let videoId = id?.toString else { return }
                let url = Constants.prodBaseUrl + name + "/clips?clip=" + videoId
                
                self.routeToShareScreen(string: url)
            }.store(in: &subscriptions)
            
            panelViewModel.subscribersCountText = shortMedia.mediaContainerChannel?.followersCount?.toString
            models.append(ShortListCollectionCellViewModel(
                id: id ?? UUID().hashValue,
                previewImageUrl: previewImageUrl,
                urlToPlay: URL(string: mediaMeta?.mediaArchiveUrl ?? ""),
                panelViewModel: panelViewModel,
                channelId: channelId
            ))
            
            panelViewModel.avatarAction.sink { [unowned self] cellModel in
                self.router.openProfile(channelId: cellModel?.channelId)
            }.store(in: &subscriptions)
            
            panelViewModel.subscribeAction.sink { [unowned self] cellModel in
                guard let channelId else { return }
                if panelViewModel.isSubscribedAction {
                    panelViewModel.isSubscribedAction = false
                    panelViewModel.subscribeChange.send(false)
                    self.networkHelper.unSubscribeToChannel(channelId: channelId)
                } else {
                    if self.router.authService?.isAuthorized == true {
                        panelViewModel.isSubscribedAction = true
                        panelViewModel.subscribeChange.send(true)
                        self.networkHelper.subscribeToChannel(channelId: channelId)
                    } else {
                        self.router.openAuthScreen()
                    }
                }
            }.store(in: &subscriptions)
            
            if let subscription = subscription {
                panelViewModel.isSubscribedAction = subscription.result.first(where: { $0.channelId == channelId }) != nil
            }
        }
        if cellModels.value.last?.id == models.last?.id || models.isEmpty {
            didPullToEnd = true
            self.outputSubject.send(.didEndRefreshing)
            return
        }
        cellModels.value = incPage ? cellModels.value + models : models
        self.outputSubject.send(.updateData(model: cellModels.value, appendingNew: incPage))
    }
    
    private func makeComplainString(
        model: MediaContainerModel
    ) -> String {
        // Example https://survey.zohopublic.com/zs/Aaz0H6#?email_user=t0st-1@yandex.ru&channel_id=1587191&user_id=1633460

        let profileStorage = UserDefaults.standard.getProfile()
        let userEmail = profileStorage?.result?.userEmail ?? "test@test.ru"

        let baseUrl = "https://survey.zohopublic.com/zs/Aaz0H6#?"
        let email = "email_user=" + userEmail

        let channelId = model.mediaContainerChannel?.channelId?.toString ?? ""
        let channel = "&channel_id=" + channelId
        
        let userId = profileStorage?.result?.userProfile?.userId.toString ?? "99999"
        let user = "&user_id=" + userId

        return baseUrl + email + channel + user
    }
}
