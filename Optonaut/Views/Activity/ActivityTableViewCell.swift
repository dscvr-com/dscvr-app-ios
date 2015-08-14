//
//  ActivityTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa
import WebImage
import TTTAttributedLabel

class ActivityTableViewCell: UITableViewCell {
    
    var navigationController: UINavigationController?
    var viewModel: ActivityViewModel!
    
    // subviews
    let avatarImageView = UIImageView()
    let textView = TTTAttributedLabel(forAutoLayout: ())
    let optographImageView = UIImageView()
    let lineView = UIView()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        avatarImageView.layer.cornerRadius = 15
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(avatarImageView)
        
        textView.numberOfLines = 2
        textView.font = UIFont.robotoOfSize(13, withType: .Regular)
        textView.textColor = UIColor(0x4d4d4d)
        contentView.addSubview(textView)
        
        optographImageView.userInteractionEnabled = true
        optographImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushDetails"))
        contentView.addSubview(optographImageView)
        
        lineView.backgroundColor = UIColor(0xe5e5e5)
        contentView.addSubview(lineView)
        
        contentView.setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        avatarImageView.autoAlignAxisToSuperviewAxis(.Horizontal)
        avatarImageView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 30, height: 30))
        
        textView.autoAlignAxisToSuperviewAxis(.Horizontal)
        textView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 12)
        textView.autoPinEdge(.Right, toEdge: .Left, ofView: optographImageView, withOffset: -12)
        
        optographImageView.autoAlignAxisToSuperviewAxis(.Horizontal)
        optographImageView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        optographImageView.autoSetDimensionsToSize(CGSize(width: 34, height: 22))
        
        lineView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: contentView)
        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        lineView.autoSetDimension(.Height, toSize: 1)
        
        super.updateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindViewModel(activity: Activity) {
        viewModel = ActivityViewModel(activity: activity)
        
        if let avatarUrl = NSURL(string: viewModel.creatorAvatarUrl.value) {
            avatarImageView.sd_setImageWithURL(avatarUrl, placeholderImage: UIImage(named: "avatar-placeholder"))
        }
        
        if let url = viewModel.optographUrl.value, imageUrl = NSURL(string: url) {
            optographImageView.sd_setImageWithURL(imageUrl, placeholderImage: UIImage(named: "optograph-placeholder"))
        }
        
        viewModel.isRead.producer
            .map { $0 ? UIColor.clearColor() : BaseColor.alpha(0.1) }
            .start(next: { self.backgroundColor = $0 })
        
        textView.rac_text <~ viewModel.activityType.producer
            .map { type in
                switch type {
                case .Like: return "\(self.viewModel.timeSinceCreated.value) \(self.viewModel.creatorUserName.value) stard your Optograph"
                case .Follow: return "\(self.viewModel.timeSinceCreated.value) \(self.viewModel.creatorUserName.value) followed you"
                default: return ""
                }
            }
    }
    
    func pushProfile() {
        let profileTableViewController = ProfileTableViewController(personId: viewModel.creatorId.value)
        navigationController?.pushViewController(profileTableViewController, animated: true)
    }
    
    func pushDetails() {
        if let id = viewModel.optographId.value {
            let detailsTableViewController = DetailsTableViewController(optographId: id)
            navigationController?.pushViewController(detailsTableViewController, animated: true)
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}
