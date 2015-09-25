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

class OptographTableViewCell: UITableViewCell {
    
    weak var navigationController: NavigationController?
    var viewModel: OptographViewModel!
    
    // subviews
    let wrapperView = UIView()
    let barView = UIView()
    let dateView = UILabel()
    let starButtonView = UIButton()
    let starsCountView = UILabel()
    let previewImageView = PlaceholderImageView()
    let locationView = UILabel()
    let displayNameView = UILabel()
    let avatarImageView = PlaceholderImageView()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .blackColor()
        
        wrapperView.layer.cornerRadius = 6
        wrapperView.clipsToBounds = true
        wrapperView.backgroundColor = .whiteColor()
        contentView.addSubview(wrapperView)
        
        previewImageView.placeholderImage = UIImage(named: "optograph-placeholder")!
        previewImageView.contentMode = .ScaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.userInteractionEnabled = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushDetails"))
        wrapperView.addSubview(previewImageView)
        
        wrapperView.addSubview(barView)
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 15
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        barView.addSubview(avatarImageView)
        
        starButtonView.titleLabel?.font = UIFont.iconOfSize(17)
        starButtonView.setTitle(String.iconWithName(.Heart), forState: .Normal)
        starButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleStar"))
        barView.addSubview(starButtonView)
        
        starsCountView.font = UIFont.robotoOfSize(12, withType: .SemiBold)
        starsCountView.textColor = .Grey
        barView.addSubview(starsCountView)
        
        displayNameView.font = UIFont.robotoOfSize(12, withType: .SemiBold)
        displayNameView.textColor = .Grey
        displayNameView.textAlignment = .Right
        displayNameView.userInteractionEnabled = true
        displayNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        barView.addSubview(displayNameView)
        
        dateView.font = UIFont.robotoOfSize(10.2, withType: .Regular)
        dateView.textColor = .Grey
        dateView.textAlignment = .Right
        barView.addSubview(dateView)
        
        locationView.font = UIFont.robotoOfSize(14, withType: .SemiBold)
        locationView.textColor = .DarkGrey
        barView.addSubview(locationView)
        
        barView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        wrapperView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        wrapperView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView)
        wrapperView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView)
        wrapperView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: contentView, withOffset: -8)
        
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: wrapperView)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: contentView, withMultiplier: 3 / 4)
        
        barView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: wrapperView)
        barView.autoPinEdge(.Left, toEdge: .Left, ofView: wrapperView, withOffset: 7)
        barView.autoPinEdge(.Right, toEdge: .Right, ofView: wrapperView, withOffset: -7)
        barView.autoSetDimension(.Height, toSize: 42)
        
        starButtonView.autoAlignAxis(.Horizontal, toSameAxisOfView: barView)
        starButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: barView, withOffset: 4) // 4pt extra for heart border
        
        starsCountView.autoAlignAxis(.Horizontal, toSameAxisOfView: barView)
        starsCountView.autoPinEdge(.Left, toEdge: .Right, ofView: starButtonView, withOffset: 3)
        
        locationView.autoAlignAxis(.Horizontal, toSameAxisOfView: barView)
        locationView.autoAlignAxis(.Vertical, toSameAxisOfView: barView)
        
        avatarImageView.autoAlignAxis(.Horizontal, toSameAxisOfView: barView)
        avatarImageView.autoPinEdge(.Right, toEdge: .Right, ofView: barView)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 29, height: 29))
        
        displayNameView.autoAlignAxis(.Horizontal, toSameAxisOfView: barView, withOffset: -6)
        displayNameView.autoPinEdge(.Right, toEdge: .Left, ofView: avatarImageView, withOffset: -7)
        
        dateView.autoAlignAxis(.Horizontal, toSameAxisOfView: barView, withOffset: 6)
        dateView.autoPinEdge(.Right, toEdge: .Left, ofView: avatarImageView, withOffset: -7)
        
        super.updateConstraints()
    }
    
    func bindViewModel(optograph: Optograph) {
        viewModel = OptographViewModel(optograph: optograph)
        
        previewImageView.rac_url <~ viewModel.previewImageUrl
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        displayNameView.rac_text <~ viewModel.displayName
        locationView.rac_text <~ viewModel.location.producer.map { $0.firstWord ?? "" } // TODO remove firstWord
        dateView.rac_text <~ viewModel.timeSinceCreated
        starsCountView.rac_text <~ viewModel.starsCount.producer.map { "\($0)" }
        starButtonView.rac_titleColor <~ viewModel.isStarred.producer.map { $0 ? UIColor.Accent : UIColor(0xe6e6e6) }
    }
    
    func pushDetails() {
        navigationController?.pushViewController(DetailsTableViewController(optographId: viewModel.optograph.id), animated: true)
    }
    
    func pushProfile() {
        navigationController?.pushViewController(ProfileTableViewController(personId: viewModel.optograph.person.id), animated: true)
    }
    
    func toggleStar() {
        viewModel.toggleLike()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}