//
//  ShortListVideoCellViewModel.swift
//  wasd
//
//  Created by Глебов Алексей on 27.06.2023.
//

import Foundation
import Combine


final class ShortListCollectionCellViewModel: Hashable {
    let id: Int
    let previewImageUrl: URL?
    let urlToPlay: URL?
    let channelId: Int?
    let panelViewModel: ShortVideoScreenPanelsViewModel
    
    init(
        id: Int,
        previewImageUrl: URL?,
        urlToPlay: URL?,
        panelViewModel: ShortVideoScreenPanelsViewModel,
        channelId: Int?
    ) {
        self.id = id
        self.previewImageUrl = previewImageUrl
        self.urlToPlay = urlToPlay
        self.panelViewModel = panelViewModel
        self.channelId = channelId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ShortListCollectionCellViewModel, rhs: ShortListCollectionCellViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
}
