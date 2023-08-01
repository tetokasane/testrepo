//
//  ShortVideoScreenViewController.swift
//  wasd
//
//  Created by Глебов Алексей on 21.04.2023.
//

import Foundation
import UIKit
import Combine
import SnapKit
import WSDNetwork

final class ShortVideoScreenViewController: UIViewController, ViewRepresentable {
    typealias ViewModel = ShortVideoScreenViewModel

    // MARK: - Public Properties

    let viewModel: ViewModel

    let backButton = UIButton(type: .system).with {
        $0.setImage(.init(.icChevronLeftWhite), for: .normal)
        $0.tintColor = UIColor(.textHeadline)
        $0.isHidden = true
    }
    var subscriptions: [AnyCancellable] = []

    // MARK: - Private Properties

    private let navigationBar = WASDCustomNavBarView()
    private let titleView = WASDNavigationTitleItemSelectorView()
    private let collectionView = ShortVideoListView(frame: .zero)

    private let input = PassthroughSubject<ShortVideoScreenViewModel.Input, Never>()

    // MARK: - Initialization

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        bindViewModel(viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        view.backgroundColor = .black
        view.isUserInteractionEnabled = true
        super.viewDidLoad()
        configureLayout()
        bind()
        input.send(.viewDidLoad)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadVideosAction.send(())
        navigationController?.isNavigationBarHidden = true
        collectionView.startCurrentPlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
        collectionView.stopCurrentPlayer()
    }

    // MARK: - Private Methods
    
    private func bind() {
        let output = viewModel.transform(inputSubject: input.eraseToAnyPublisher())

        output.sink { [weak self] event in
            switch event {
            case .didEndRefreshing:
                self?.collectionView.didEndRefreshing.send(())
            case .updateData(let model, let appendingNew):
                self?.collectionView.cellModels.send((model, appendingNew: appendingNew))
            }
        }.store(in: &subscriptions)
        
        collectionView.didStartRefreshing.sink { [unowned self] _ in
            self.input.send(.didStartRefreshing)
        }.store(in: &subscriptions)
        
        collectionView.didScrollToEnd.sink { [unowned self] _ in
            self.input.send(.didScrollToEnd)
        }.store(in: &subscriptions)

        backButton.tapPublisher.sink { [unowned self] in
            self.input.send(.navBar(action: .onBackTap))
        }.store(in: &subscriptions)
    }
    
    private func bindViewModel(_ viewModel: ShortVideoScreenViewModel) {
        viewModel.currentNavItems.subscribe(titleView.currentItemsSubject).store(in: &subscriptions)
        titleView.currentSelectedItemIndex.value = 0
    }
    
    private func configureLayout() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaInsets.top)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        view.addSubview(navigationBar)
        navigationBar.snp.makeConstraints {
            $0.topMargin.equalTo(view.snp.topMargin).offset(20)
            $0.left.right.equalToSuperview()
        }

        backButton.snp.makeConstraints {
            $0.size.equalTo(24)
        }
        
        navigationBar.leftViews = [backButton]
        navigationBar.titleView = titleView
    }
}
