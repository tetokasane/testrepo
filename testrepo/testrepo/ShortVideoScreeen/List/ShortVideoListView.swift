//
//  ShortVideoListView.swift
//  wasd
//
//  Created by Глебов Алексей on 26.06.2023.
//

import UIKit
import Combine
import SnapKit
import Kingfisher

public class ShortVideoListView: UIView {
    
    enum SectionType: Hashable {
        case videos
    }

    // MARK: - Public Properties
    
    let cellModels: CurrentValueSubject<([ShortListCollectionCellViewModel], appendingNew: Bool), Never> = .init(([], false))
    let didSelectItemSubject: PassthroughSubject<Int, Never> = .init()
    let didStartRefreshing: PassthroughSubject<Void, Never> = .init()
    let didEndRefreshing: PassthroughSubject<Void, Never> = .init()
    let didScrollToEnd: PassthroughSubject<Void, Never> = .init()

    // MARK: - Private properties

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout()).with {
        $0.register(ShortListCollectionViewCell.self)
        $0.backgroundColor = .clear
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceHorizontal = false
        $0.contentInsetAdjustmentBehavior = .never
        $0.delegate = self
    }
    
    private lazy var refreshControl = CustomRefreshControl().with {
        $0.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    private var dataSource: UICollectionViewDiffableDataSource<SectionType, ShortListCollectionCellViewModel>?
    private var subscriptions = Set<AnyCancellable>()
    private var currentCell: ShortListCollectionViewCellProtocol?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createDataSource()
        configureBindings()
        cellModels
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] (cellModels, appendingNew) in
                guard var snapshot = (dataSource as? UICollectionViewDiffableDataSource)?.snapshot() else { return }
                if appendingNew {
                    snapshot.appendItems(cellModels, toSection: SectionType.videos)
                    dataSource?.apply(snapshot, animatingDifferences: true)
                } else {
                    snapshot.deleteAllItems()
                    snapshot.appendSections([SectionType.videos])
                    snapshot.appendItems(cellModels, toSection: SectionType.videos)

                    dataSource?.apply(snapshot, animatingDifferences: false)

                }
        }.store(in: &subscriptions)

        addSubview(
            collectionView
        )
    }
        
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        configureLayout()
        refreshControl.bounds = CGRect(x: refreshControl.bounds.origin.x,
                                       y: -100,
                                       width: refreshControl.bounds.size.width,
                                       height: 400)

        collectionView.refreshControl = refreshControl
    }

    // MARK: - Public methods

    public func stopCurrentPlayer() {
        currentCell?.stopPlayer()
    }
    
    public func startCurrentPlayer() {
        currentCell?.startPlayer()
    }

    // MARK: - Private methods

    private func configureLayout() {

        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func configureBindings() {
        didEndRefreshing.sink { [unowned self] _ in
            self.refreshControl.endRefreshing()
        }.store(in: &subscriptions)
    }
    
    @objc private func refreshData() {
        refreshControl.rotate()
        
        self.collectionView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                  self.refreshControl.endRefreshing()
                  self.collectionView.contentInset = UIEdgeInsets.zero
                  self.collectionView.setContentOffset(.zero, animated: true)
                }
        didStartRefreshing.send(())
    }
        
    private func makeLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let layoutGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [layoutItem]
        )

        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        layoutSection.orthogonalScrollingBehavior = .groupPaging

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.contentInsetsReference = .none
        config.scrollDirection = .horizontal

        let layout = UICollectionViewCompositionalLayout(section: layoutSection, configuration: config)
        return layout
    }
    
    func createDataSource() {
        dataSource = UICollectionViewDiffableDataSource<SectionType, ShortListCollectionCellViewModel>(
            collectionView: collectionView,
            cellProvider: { [unowned self] collectionView, indexPath, model in
                let cell = collectionView.dequeue(for: indexPath, cellType: ShortListCollectionViewCell.self)
                let cellModel = self.cellModels.value.0[indexPath.row]
                cell.setup(with: cellModel)
                return cell
            })
    }

}
// MARK: - UICollectionViewDelegate

extension ShortVideoListView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ShortListCollectionViewCellProtocol {
            if cell.isPlayerRunning {
                cell.stopPlayer()
            } else if cell.isPlayerReadyToPlay {
                cell.resumePlayer()
            } else {
                cell.startPlayer()
            }
        }
        didSelectItemSubject.send(indexPath.row)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ShortListCollectionViewCellProtocol {
            cell.stopPlayer()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ShortListCollectionViewCellProtocol {
            cell.startPlayer()
            currentCell = cell
        } else {
            didScrollToEnd.send(())
        }
        if indexPath.row == cellModels.value.0.count - 2 {
            didScrollToEnd.send(())
        }
    }
}
