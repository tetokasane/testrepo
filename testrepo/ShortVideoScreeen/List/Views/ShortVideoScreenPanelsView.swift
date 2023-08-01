//
//  ShortVideoScreenBottomPanel.swift
//  wasd
//
//  Created by Глебов Алексей on 13.04.2023.
//

import Kingfisher
import UIKit
import SnapKit
import Combine

protocol ShortVideoScreenPanelsView: UIView {
    var viewModel: ShortVideoScreenPanelsViewModel? { get set }
    var parentCellModel: ShortListCollectionCellViewModel? { get set }
    func resetBindings()
    init()
}

final class ShortVideoScreenPanelsViewImpl: UIView, ShortVideoScreenPanelsView {
    
    // MARK: - Constants
    private enum Constants {
        enum ConstraintItems {
            static let btnWidthHeigthOffset = 32
            static let iconViewWidthHeigthOffset = 16
            static let shareButtonSize = 32
            static let iconViewLeftOffset = 16
            static let iconViewRightOffset = 10
            static let descriptionTextLabelOffset = 12
            static let subscribersCountRightOffset = 20
            static let iconVerifiedViewLeftOffset = 6
            static let iconAvatarViewSize = 40
            static let descriptionLabelRightOffset = 20
            static let hStackRightOffset = 12
            static let hStackLeftOffset = 12
            static let vButtonsRightInset = 13
        }
        static let hStackSpacing: CGFloat = 8
        static let vButtonsStackSpacing: CGFloat = 20
        static let youHaveSubscribedText = "Вы подписаны"
        static let youHaveSubscribedCornerRadius: CGFloat = 20
        
        enum Strings {
            static let subscribers = "подписчиков"
            static let buttonIsSubscriberText = "Вы подписаны"
            static let buttonNonSubscriberText = "Подписаться"
        }
    }
    
    // MARK: - Public properties
    var viewModel: ShortVideoScreenPanelsViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }
            bindViewModel(viewModel)
        }
    }
    var parentCellModel: ShortListCollectionCellViewModel?
    
    // MARK: - Private properties
    private var subscriptions: Set<AnyCancellable> = .init([])
    private var moreActionSubscription: AnyCancellable?
    
    // MARK: - Stack views
    private let hStackView = UIStackView()
    private let vButtonsStackView = UIStackView()
    private let textBox = UIView()
    
    // MARK: - Icons
    private let iconVerifiedView = UIImageView(.verified)
    private lazy var iconCheckView: UIImageView = {
        let view = UIImageView(.shortsIcCheck)
        view.tintColor = UIColor(.textHeadline)
        return view
    }()
    private let iconSearchView = UIImageView(.search)
    
    // @TODO: - Delete
    private lazy var iconAvatarView = UIImageView().apply {
        $0.contentMode = .scaleAspectFill
        $0.isUserInteractionEnabled = true
        $0.setCornerRadius(20)
    }
    
    // MARK: - Buttons
    private lazy var shareButton = UIButton(type: .system).with { button in
        button.setImage(.init(.shortsIcShare), for: .normal)
        button.tintColor = UIColor(.textHeadline)
    }
                                                   
    private lazy var heartEmptyButton = UIButton(type: .system).with { button in
        let iconView = UIImageView()
        iconView.tintColor = .white
        button.setImage(.init(.shortsIcHeart), for: .normal)
        button.tintColor = UIColor(.textHeadline)
    }
        
    private lazy var heartFilledButton = UIButton(type: .system).with { button in
        button.setImage(.init(.shortsIcHeartFilled), for: .normal)
        button.tintColor = UIColor(.textHeadline)
    }
    
    private lazy var moreButton = UIButton(type: .system).with { button in
        button.setImage(.init(.shortsIcMore).withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor(.textHeadline)
    }
    
    private let subscribeButton = UIButton().apply {
        $0.setTitleColor(UIColor(.textHeadline), for: .normal)
        $0.setTitle(Constants.Strings.buttonNonSubscriberText, for: .normal)
        $0.setCornerRadius(17) 
        
        var configuration = UIButton.Configuration.plain()
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ transofrm in
            var output = transofrm
            output.font = .captionMMedium
            return output
        })
        $0.configuration = configuration
    }
    
    // MARK: - Labels
    private lazy var nameLabel = UILabel().with { label in
        label.font = .bodySMedium
        label.textColor = .white
        label.numberOfLines = 1
    }
    private lazy var subscribersCountLabel = UILabel().with { label in
        label.font = .bodySRegular
        label.textColor = .white
        label.numberOfLines = 1
    }
    private lazy var descriptionTextLabel = UILabel().with { label in
        label.textColor = .init(.textPrimary)
        label.font = .bodySRegular
        label.numberOfLines = 2
    }
    
    // MARK: - Init
    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = true
        configureLayout()
        configureHorizontalPanel()
        configureVerticalPanel()
        configureDescriptionToggler()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public properties
    
    public func resetBindings() {
        subscriptions.removeAll()
    }
    
    // MARK: - Layout
    
    private func configureLayout() {
        addSubviews([descriptionTextLabel, hStackView, vButtonsStackView])
        textBox.addSubview(nameLabel)
        textBox.addSubview(subscribersCountLabel)

        descriptionTextLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(Constants.ConstraintItems.descriptionTextLabelOffset)
            $0.right.equalTo(vButtonsStackView.snp.leftMargin)
            $0.left.equalToSuperview().offset(Constants.ConstraintItems.descriptionTextLabelOffset)
        }
        
        addSubview(subscribeButton)
        subscribeButton.snp.makeConstraints {
            $0.height.equalTo(33)
            $0.centerY.equalTo(hStackView.snp.centerY)
            $0.width.greaterThanOrEqualTo(117)
            $0.right.equalToSuperview().inset(61)
        }
        
        hStackView.snp.makeConstraints {
            $0.bottom.equalTo(descriptionTextLabel.snp.top)
            $0.left.equalToSuperview().inset(Constants.ConstraintItems.hStackRightOffset)
        }
        
        vButtonsStackView.snp.makeConstraints {
            $0.right.equalToSuperview().inset(Constants.ConstraintItems.vButtonsRightInset)
            $0.bottom.equalToSuperview()
        }
        
        shareButton.snp.makeConstraints {
            $0.size.equalTo(Constants.ConstraintItems.shareButtonSize)
        }
        
        heartEmptyButton.snp.makeConstraints {
            $0.height.width.equalTo(Constants.ConstraintItems.btnWidthHeigthOffset)
        }
        
        heartFilledButton.snp.makeConstraints {
            $0.width.height.equalTo(Constants.ConstraintItems.btnWidthHeigthOffset)
        }
        
        moreButton.snp.makeConstraints {
            $0.width.height.equalTo(Constants.ConstraintItems.btnWidthHeigthOffset)
        }
        
        iconAvatarView.snp.makeConstraints {
            $0.width.height.equalTo(Constants.ConstraintItems.iconAvatarViewSize)
        }
        
        subscribersCountLabel.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview().inset(Constants.ConstraintItems.subscribersCountRightOffset).priority(.medium)
            $0.top.equalToSuperview()
        }
        /* @TODO: UGCNAVI-605 REMOVE VERIFIED VIEW
        textBox.addSubview(iconVerifiedView)
        iconVerifiedView.snp.makeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(Constants.ConstraintItems.iconVerifiedViewLeftOffset)
            make.top.equalTo(nameLabel.snp.top)
        }*/
        nameLabel.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
    
    private func configureDescriptionToggler() {
        let button = UIButton()
        addSubview(button)
        button.backgroundColor = .clear
        button.snp.makeConstraints {
            $0.edges.equalTo(descriptionTextLabel.snp.edges)
        }
        button.tapPublisher.sink { [weak self] _ in
            self?.toggleDescription()
        }.store(in: &subscriptions)
    }
    
    private func configureHorizontalPanel() {
        hStackView.isUserInteractionEnabled = true
        hStackView.axis = .horizontal
        hStackView.alignment = .center
        hStackView.distribution = .fillProportionally
        hStackView.spacing = Constants.hStackSpacing
        hStackView.addArrangedSubview(iconAvatarView)
        hStackView.addArrangedSubview(textBox)
    }
    
    private func configureVerticalPanel() {
        vButtonsStackView.axis = .vertical
        vButtonsStackView.spacing = Constants.vButtonsStackSpacing
        vButtonsStackView.addArrangedSubview(shareButton)
        vButtonsStackView.addArrangedSubview(moreButton)
    }
    
    private func bindViewModel(_ viewModel: ShortVideoScreenPanelsViewModel) {
        // TODO: Remove
        nameLabel.text = viewModel.nameText
        var text = viewModel.descriptionText ?? ""
        if text.count > 250 {
            text = text.prefix(250) + "..."
        }
        descriptionTextLabel.text = text
        subscribersCountLabel.text = (viewModel.subscribersCountText ?? "0") + " " + Constants.Strings.subscribers
        subscriptionToggle(isSubscription: viewModel.isSubscribedAction)
        iconAvatarView.kf.setImage(with: viewModel.avatarImageUrl)
        
        shareButton.tapPublisher.map { self.parentCellModel }.subscribe(viewModel.shareAction).store(in: &subscriptions)

        moreActionSubscription = moreButton.tapPublisher.map { self.parentCellModel }.subscribe(viewModel.moreAction)

        heartEmptyButton.tapPublisher.map { (self.parentCellModel, true) }.subscribe(viewModel.heartAction).store(in: &subscriptions)
        heartFilledButton.tapPublisher.map { (self.parentCellModel, false) }.subscribe(viewModel.heartAction).store(in: &subscriptions)
        
        subscribeButton.tapPublisher.map { (self.parentCellModel) }.subscribe(viewModel.subscribeAction).store(in: &subscriptions)
        
        iconAvatarView.publisher.sink { _ in
            viewModel.avatarAction.send(self.parentCellModel)
        }.store(in: &subscriptions)
        
        viewModel.subscribeChange.sink { [weak self] isSubscribe in
            self?.subscriptionToggle(isSubscription: isSubscribe)
        }.store(in: &subscriptions)
    }
    
    private func toggleDescription() {
        if descriptionTextLabel.numberOfLines == 0 {
            descriptionTextLabel.numberOfLines = 2
        } else {
            descriptionTextLabel.numberOfLines = 0
        }
        setNeedsLayout()
    }
    
    private func subscriptionToggle(isSubscription: Bool) {
        let buttonText = isSubscription ? Constants.Strings.buttonIsSubscriberText : Constants.Strings.buttonNonSubscriberText
        let backgroundSubscribe = isSubscription ? UIColor(.textHeadline).withAlphaComponent(0.08) : UIColor(.textHeadline).withAlphaComponent(0.32)
        subscribeButton.backgroundColor = backgroundSubscribe
        subscribeButton.setTitle(buttonText, for: .normal)
        
        if isSubscription {
            subscribeButton.configuration?.imagePadding = 4
            subscribeButton.configuration?.image = UIImage(.subscribe)
        } else {
            subscribeButton.configuration?.image = nil
        }
    }
}
