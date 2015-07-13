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
        super.init(coder: aDecoder)
    }
    
    func bindViewModel(activity: Activity) {
        viewModel = ActivityViewModel(activity: activity)
        
        if let avatarUrl = NSURL(string: viewModel.creatorAvatarUrl.value) {
            avatarImageView.sd_setImageWithURL(avatarUrl, placeholderImage: UIImage(named: "avatar-placeholder"))
        }
        
        if let optographUrl = viewModel.optographUrl.value, imageUrl = NSURL(string: optographUrl) {
            optographImageView.sd_setImageWithURL(imageUrl, placeholderImage: UIImage(named: "optograph-placeholder"))
        }
        
        viewModel.activityType.producer
            |> start(next: { type in
        
                var text = ""
                switch type {
                case .Like: text = "\(self.viewModel.timeSinceCreated.value) \(self.viewModel.creatorUserName.value) liked your Optograph"
                case .Follow: text = "\(self.viewModel.timeSinceCreated.value) \(self.viewModel.creatorUserName.value) followed you"
                default: ()
                }
                
                self.textView.text = text
            })
        
//        dateView.rac_text <~ viewModel.timeSinceCreated
        
//        textView.rac_text <~ viewModel.text
    }
    
    func pushProfile() {
        let profileViewController = ProfileViewController(userId: viewModel.creatorId.value)
        navigationController?.pushViewController(profileViewController, animated: true)
    }
    
    func pushDetails() {
        let optograph = viewModel.optograph.value!
        let detailsViewController = DetailsViewController(optographId: optograph.id)
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}
