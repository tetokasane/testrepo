//
//  ShortVideoNetworkHelper.swift
//  wasd
//
//  Created by Мелёшин Никита on 23.07.2023.
//

import Foundation

enum ShortsFetchResult {
    case mediaContainer(MediaContainerArrayModel)
    case subscription(SubscriptionsModel)
}

class ShortNetworkHelper {
    
    // MARK: - Private properties
    
    private var serviceBuilder: ServiceBuilderProtocol?
    
    // MARK: - Init
    
    init(serviceBuilder: ServiceBuilderProtocol?) {
        self.serviceBuilder = serviceBuilder
    }
    
    // MARK: - Public methods
    
    func getShorts(sortType: String?, channelId: Int?, offset: Int?) async throws -> MediaContainerArrayModel? {
        guard let serviceBuilder else { return nil }
        let query = MediaContainerQueryModel(includeDeleted: false, includeRestricted: false, excludeClosed: true, mediaContainerStatus: "STOPPED", mediaContainerOnlineStatus: "PUBLIC", orderType: sortType != nil ? sortType : "DATE", orderDirection: "DESC", mediaContainerType: ["SHORT_VIDEO"], channelId: channelId, offset: offset)
        return try await serviceBuilder.getMediaContainerData(query)
    }
    
    func getSubscriptions() async throws -> SubscriptionsModel? {
        guard let serviceBuilder else { return nil }
        
        return try await serviceBuilder.getSubscriptionsData(limit: 100, offset: 0, orderType: .activity)
    }
    
    func subscribeToChannel(channelId: Int?) {
        guard let serviceBuilder, let channelId else { return }
        Task.detached {
            do {
                try await serviceBuilder.subscribeToChannel(id: channelId)
            } catch {}
        }
    }
    
    func unSubscribeToChannel(channelId: Int?) {
        guard let serviceBuilder, let channelId else { return }
        Task.detached {
            do {
                try await serviceBuilder.unsubscribeFromChannel(id: channelId)
            } catch {}
        }
    }
    
}
