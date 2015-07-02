//
//  OptographTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import FontAwesome
import ReactiveCocoa
import WebImage

class OptographTableViewCell: UITableViewCell {
    
    var navController: UINavigationController?
    var viewModel: OptographViewModel!
    
    // subviews
    let previewImageView = UIImageView()
    let likeButtonView = UIButton()
    let numberOfLikesView = UILabel()
    let dateView = UILabel()
    let shareButtonView = UIButton()
    let textView = KILabel()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        previewImageView.userInteractionEnabled = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showDetails"))
        contentView.addSubview(previewImageView)
        
        likeButtonView.titleLabel?.font = UIFont.fontAwesomeOfSize(20)
        likeButtonView.setTitle(String.fontAwesomeIconWithName(FontAwesome.Heart), forState: .Normal)
        contentView.addSubview(likeButtonView)
        
        let gray = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        
        numberOfLikesView.font = UIFont.boldSystemFontOfSize(16)
        numberOfLikesView.textColor = gray
        contentView.addSubview(numberOfLikesView)
        
        dateView.font = UIFont.systemFontOfSize(16)
        dateView.textColor = gray
        contentView.addSubview(dateView)
        
        shareButtonView.titleLabel?.font = UIFont.fontAwesomeOfSize(20)
        shareButtonView.setTitle(String.fontAwesomeIconWithName(FontAwesome.ShareAlt), forState: .Normal)
        shareButtonView.setTitleColor(gray, forState: .Normal)
        contentView.addSubview(shareButtonView)
        
        textView.numberOfLines = 0
        textView.tintColor = baseColor()
        textView.userInteractionEnabled = true
        contentView.addSubview(textView)
        
        contentView.setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: contentView)
        
        likeButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 10)
        likeButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 12)
        
        numberOfLikesView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 16)
        numberOfLikesView.autoPinEdge(.Left, toEdge: .Right, ofView: likeButtonView, withOffset: 5)
        
        dateView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 16)
        dateView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -15)
        
        shareButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 10)
        shareButtonView.autoPinEdge(.Right, toEdge: .Left, ofView: dateView, withOffset: -5)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 46)
        textView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 15)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -15)
        
        super.updateConstraints()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func bindViewModel(optograph: Optograph) {
        viewModel = OptographViewModel(optograph: optograph)
        
        if let imageUrl = NSURL(string: viewModel.imageUrl.value) {
            previewImageView.sd_setImageWithURL(imageUrl, placeholderImage: UIImage(named: "placeholder"))
        }
        numberOfLikesView.rac_text <~ viewModel.numberOfLikes.producer |> map { num in "\(num)" }
        dateView.rac_text <~ viewModel.timeSinceCreated
        
        likeButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.toggleLike()
            return RACSignal.empty()
        })
        
        viewModel.liked.producer
            |> map { $0 ? baseColor() : .grayColor() }
            |> start(next: { self.likeButtonView.setTitleColor($0, forState: .Normal)})
        
        textView.rac_text <~ viewModel.text
        textView.userHandleLinkTapHandler = { label, handle, range in
            let profileViewController = ProfileViewController(userId: self.viewModel.userId.value)
            self.navController?.pushViewController(profileViewController, animated: true)
        }
        textView.hashtagLinkTapHandler = { label, hashtag, range in
            let searchViewController = SearchTableViewController(initialKeyword: hashtag, navController: self.navController)
            self.navController?.pushViewController(searchViewController, animated: true)
        }
    }
    
    func showDetails() {
        let detailsViewController = DetailsViewController(viewModel: viewModel)
        navController?.pushViewController(detailsViewController, animated: true)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}