//
//  OptographTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa
import HexColor
import ActiveLabel

class OptographTableViewCell: UITableViewCell {
    
    weak var navigationController: NavigationController?
    var viewModel: OptographViewModel!
    
    // subviews
    private let previewImageView = PlaceholderImageView()
    private let avatarImageView = PlaceholderImageView()
    private let locationIconView = UILabel()
    private let locationTextView = UILabel()
    private let locationCountryView = UILabel()
    private let dateView = UILabel()
    private let starButtonView = UIButton()
    private let starsCountView = UILabel()
    private let optionsButtonView = UIButton()
    private let bottomBackgroundView = BackgroundView()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .whiteColor()
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(avatarImageView)
        
        locationIconView.text = String.iconWithName(.Location)
        locationIconView.font = UIFont.iconOfSize(15)
        locationIconView.textColor = .DarkGrey
        contentView.addSubview(locationIconView)
        
        locationTextView.font = UIFont.displayOfSize(16.5, withType: .Semibold)
        locationTextView.textColor = .DarkGrey
        contentView.addSubview(locationTextView)
        
        locationCountryView.font = UIFont.displayOfSize(16.5, withType: .Thin)
        locationCountryView.textColor = .DarkGrey
        contentView.addSubview(locationCountryView)
        
        dateView.font = UIFont.displayOfSize(13, withType: .Thin)
        dateView.textColor = UIColor(0xb3b3b3)
        contentView.addSubview(dateView)
        
        starButtonView.titleLabel?.font = UIFont.iconOfSize(23.5)
        starButtonView.setTitle(String.iconWithName(.HeartFilled), forState: .Normal)
        starButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleStar"))
        contentView.addSubview(starButtonView)
        
        starsCountView.font = UIFont.displayOfSize(14, withType: .Thin)
        starsCountView.textColor = .Grey
        contentView.addSubview(starsCountView)
        
        optionsButtonView.titleLabel?.font = UIFont.iconOfSize(23.5)
        optionsButtonView.setTitle(String.iconWithName(.MoreOptions), forState: .Normal)
        optionsButtonView.setTitleColor(.Grey, forState: .Normal)
        optionsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "didTapOptions"))
        contentView.addSubview(optionsButtonView)
        
        previewImageView.placeholderImage = UIImage(named: "optograph-placeholder")!
        previewImageView.contentMode = .ScaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.userInteractionEnabled = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushDetails"))
        contentView.addSubview(previewImageView)
        
        contentView.addSubview(bottomBackgroundView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: contentView, withMultiplier: 3 / 4)
        
        avatarImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 19)
        avatarImageView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 20)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 40, height: 40))
        
        locationIconView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: 5)
        locationIconView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 12)
        locationIconView.autoSetDimension(.Width, toSize: 15)
        locationIconView.autoSetDimension(.Height, toSize: 15)
        
        locationTextView.autoPinEdge(.Top, toEdge: .Top, ofView: locationIconView, withOffset: -2)
        locationTextView.autoPinEdge(.Left, toEdge: .Right, ofView: locationIconView, withOffset: 4)
        
        locationCountryView.autoPinEdge(.Top, toEdge: .Top, ofView: locationTextView)
        locationCountryView.autoPinEdge(.Left, toEdge: .Right, ofView: locationTextView, withOffset: 5)
        
        dateView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: avatarImageView, withOffset: 1)
        dateView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 15)
        
        starButtonView.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        starButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -23.5) // 3.5pt extra for heart border
        
        starsCountView.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        starsCountView.autoPinEdge(.Right, toEdge: .Left, ofView: starButtonView, withOffset: -10)
        
        optionsButtonView.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        optionsButtonView.autoPinEdge(.Right, toEdge: .Left, ofView: starButtonView, withOffset: -35)
        
        bottomBackgroundView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 12)
        bottomBackgroundView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Top)
        
        super.updateConstraints()
    }
    
    func bindViewModel(optograph: Optograph) {
        viewModel = OptographViewModel(optograph: optograph)
        
        previewImageView.rac_url <~ viewModel.previewImageUrl
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        locationTextView.rac_text <~ viewModel.locationText
        locationCountryView.rac_text <~ viewModel.locationCountry
        dateView.rac_text <~ viewModel.timeSinceCreated
        starButtonView.rac_titleColor <~ viewModel.isStarred.producer.map { $0 ? .Accent : .Grey }
        starsCountView.rac_text <~ viewModel.starsCount.producer.map { "\($0)" }
    }
    
    func pushDetails() {
        navigationController?.pushViewController(DetailsTableViewController(optographId: viewModel.optograph.id), animated: true)
    }
    
    func pushProfile() {
        navigationController?.pushViewController(ProfileTableViewController(personId: viewModel.personId.value), animated: true)
    }
    
    func toggleStar() {
        viewModel.toggleLike()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}


// MARK: - OptographOptions
extension OptographTableViewCell: OptographOptions {
    
    func didTapOptions() {
        showOptions(viewModel.optograph)
    }
    
}