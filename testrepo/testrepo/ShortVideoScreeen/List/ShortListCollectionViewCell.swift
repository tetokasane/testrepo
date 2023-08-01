//
//  ShortListCollectionViewCell.swift
//  wasd
//
//  Created by Глебов Алексей on 27.06.2023.
//

import UIKit
import SnapKit

protocol ShortListCollectionViewCellProtocol {
    /// Настройка ячейки
    /// - Parameter model: модель данных
    func setup(with model: ShortListCollectionCellViewModel)
    func stopPlayer()
    func startPlayer()
    func resumePlayer()
    var isPlayerRunning: Bool { get }
    var isPlayerReadyToPlay: Bool { get }
}

final class ShortListCollectionViewCell: UICollectionViewCell, ShortListCollectionViewCellProtocol, Reusable {

    // MARK: - Constants

    enum Constants {
        enum Offsets {
            static let bottom = 100
        }
    }

    // MARK: - Private properties

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.setCornerRadius(12)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let panelsView: ShortVideoScreenPanelsView = ShortVideoScreenPanelsViewImpl()
    private let playerView = AVPlayerLayerView(backgroundColor: .clear)
    private var viewModel: ShortListCollectionCellViewModel?

    var isPlayerReadyToPlay: Bool {
        return playerView.isReadyToPlay
    }

    var isPlayerRunning: Bool {
        return playerView.isPlaying
    }

    // MARK: - Initilization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureLayout()
        prepareNotifications()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func prepareForReuse() {
        playerView.pause()
        playerView.isHidden = true
        backgroundImageView.kf.cancelDownloadTask()
        self.viewModel = nil
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public methods

    func setup(with model: ShortListCollectionCellViewModel) {
        self.viewModel = model
        panelsView.parentCellModel = viewModel
        panelsView.viewModel = model.panelViewModel
        backgroundImageView.kf.setImage(with: model.previewImageUrl)
        playerView.videoGravity = .resizeAspectFill
    }

    func stopPlayer() {
        playerView.pause()
    }

    func resumePlayer() {
        playerView.play()
    }

    func startPlayer() {
        let videoUrl = viewModel?.urlToPlay
        playerView.startPlayback(of: .init(asset: .init(url: videoUrl!))) { [unowned self] _ in
            self.playerView.isHidden = false
            self.backgroundImageView.isHidden = true
        }
    }

    // MARK: - Private methods

    private func configureLayout() {
        addSubview(backgroundImageView)
        addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        addSubview(playerView)
        playerView.snp.makeConstraints {
            $0.top.equalTo(safeAreaInsets.top)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
        playerView.isHidden = true
        addSubview(panelsView)
        panelsView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview()
            $0.bottom.equalTo(snp.bottom).inset(12)
        }
    }

    private func prepareNotifications() {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerView.player.currentItem, queue: .main) { [weak self] _ in
            self?.playerView.player.seek(to: .zero)
            self?.playerView.player.play()
        }
    }
}
