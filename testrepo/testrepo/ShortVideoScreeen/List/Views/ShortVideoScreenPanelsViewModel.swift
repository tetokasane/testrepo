//
//  ShortVideoScreenPanelsViewModel.swift
//  wasd
//
//  Created by Глебов Алексей on 13.94.2023.
//

import Foundation
import Combine

protocol ShortVideoScreenPanelsViewModelInput: AnyObject {
    var likeAction: PassthroughSubject<ShortListCollectionCellViewModel?, Never> { get }
    var shareAction: PassthroughSubject<ShortListCollectionCellViewModel?, Never> { get }
    var moreAction: PassthroughSubject<ShortListCollectionCellViewModel?, Never> { get }
    var subscribeAction: PassthroughSubject<ShortListCollectionCellViewModel?, Never> { get }
    var heartAction: PassthroughSubject<(ShortListCollectionCellViewModel?, Bool), Never> { get }
    var avatarAction: PassthroughSubject<ShortListCollectionCellViewModel?, Never> { get }
}

protocol ShortVideoScreenPanelsViewModelOutput: AnyObject {
    var heartStatus: CurrentValueSubject<Bool, Never> { get }
    var nameText: String? { get set }
    var descriptionText: String? { get set }
    var isSubscribedAction: Bool { get set }
    var subscribersCountText: String? { get set }
    var avatarImageUrl: URL? { get set }
    var subscribeChange: PassthroughSubject<Bool, Never> { get }
}

protocol ShortVideoScreenPanelsViewModel: ShortVideoScreenPanelsViewModelInput & ShortVideoScreenPanelsViewModelOutput { }

class ShortVideoScreenPanelsViewModelImpl: ShortVideoScreenPanelsViewModel {
    let likeAction = PassthroughSubject<ShortListCollectionCellViewModel?, Never>()
    let shareAction = PassthroughSubject<ShortListCollectionCellViewModel?, Never>()
    let moreAction = PassthroughSubject<ShortListCollectionCellViewModel?, Never>()
    let subscribeAction = PassthroughSubject<ShortListCollectionCellViewModel?, Never>()
    let heartAction = PassthroughSubject<(ShortListCollectionCellViewModel?, Bool), Never>()
    let avatarAction = PassthroughSubject<ShortListCollectionCellViewModel?, Never>()
    
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        heartAction.map { $1 }.eraseToAnyPublisher().subscribe(heartStatus).store(in: &subscriptions)
    }

   let subscribeChange = PassthroughSubject<Bool, Never>()
   let heartStatus: CurrentValueSubject<Bool, Never> = .init(false)
   var nameText: String?
   var descriptionText: String?
   var subscribersCountText: String?
   var avatarImageUrl: URL?
   var isSubscribedAction: Bool = false
}
