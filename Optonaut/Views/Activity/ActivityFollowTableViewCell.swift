//
//  ActivityFollowTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa

class ActivityFollowTableViewCell: ActivityTableViewCell {
    
    
    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        causingImageView.userInteractionEnabled = true
        causingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ActivityFollowTableViewCell.pushProfile)))
        
        nameView.userInteractionEnabled = true
        nameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ActivityFollowTableViewCell.pushProfile)))
        
        followBack.userInteractionEnabled = true
        followBack.setBackgroundImage(UIImage(named:"follow_inactive"), forState: .Normal)
        followBack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleFollow)))
        contentView.addSubview(followBack)
        
        alreadyFollow.userInteractionEnabled = true
        alreadyFollow.setBackgroundImage(UIImage(named:"follow_active"), forState: .Normal)
        alreadyFollow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleFollow)))
        contentView.addSubview(alreadyFollow)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        
        followBack.autoAlignAxisToSuperviewAxis(.Horizontal)
        followBack.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -30)
        let imageSize = UIImage(named:"follow_inactive")!.size
        followBack.autoSetDimensionsToSize(CGSize(width: imageSize.width, height: imageSize.height))
        
        alreadyFollow.autoAlignAxisToSuperviewAxis(.Horizontal)
        alreadyFollow.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -30)
        let imageSize2 = UIImage(named:"follow_active")!.size
        alreadyFollow.autoSetDimensionsToSize(CGSize(width: imageSize2.width, height: imageSize2.height))
        
        super.updateConstraints()
    }
    
    override func update(activity: Activity) {
        if self.activity != activity {
            
            let imageUrl = ImageURL("persons/\(activity.activityResourceFollow!.causingPerson.ID)/\(activity.activityResourceFollow!.causingPerson.avatarAssetID).jpg", width: 47, height: 47)
            causingImageView.kf_setImageWithURL(NSURL(string:imageUrl)!)
            
            Models.persons.touch(activity.activityResourceFollow!.causingPerson).insertOrUpdate()
            
            nameView.text = activity.activityResourceFollow!.causingPerson.userName
            
            if activity.activityResourceFollow!.causingPerson.isFollowed {
                followBack.hidden = true
                alreadyFollow.hidden = false
            } else {
                followBack.hidden = false
                alreadyFollow.hidden = true
            }
        }
        
        super.update(activity)
    }
    
    func toggleFollow() {
        
        let userModel = Models.persons[activity.activityResourceFollow!.causingPerson.ID]!
        let followedBefore = activity.activityResourceFollow!.causingPerson.isFollowed
        
        SignalProducer<Bool, ApiError>(value: followedBefore)
            .flatMap(.Latest) { followedBefore in
                followedBefore
                    ? ApiService<EmptyResponse>.delete("persons/\(self.activity.activityResourceFollow!.causingPerson.ID)/follow")
                    : ApiService<EmptyResponse>.post("persons/\(self.activity.activityResourceFollow!.causingPerson.ID)/follow", parameters: nil)
            }
            .on(
                started: { [weak self] in
                        userModel.insertOrUpdate { box in
                            box.model.isFollowed = !followedBefore
                    }
                    if !followedBefore {
                        self?.followBack.hidden = true
                        self?.alreadyFollow.hidden = false
                    } else {
                        self?.followBack.hidden = false
                        self?.alreadyFollow.hidden = true
                    }
                },
                failed: { [weak self] _ in
                        userModel.insertOrUpdate { box in
                            box.model.isFollowed = followedBefore
                    }
                }
            )
            .start()
    }
    
    func pushProfile() {
        let profilepage = ProfileCollectionViewController(personID: self.activity.activityResourceFollow!.causingPerson.ID)
        profilepage.isProfileVisit = true
        self.navigationController?.pushViewController(profilepage, animated: true)
    }
}