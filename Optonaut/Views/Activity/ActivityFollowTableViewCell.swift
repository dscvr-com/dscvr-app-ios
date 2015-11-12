//
//  ActivityFollowTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

class ActivityFollowTableViewCell: ActivityTableViewCell {
    
    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        causingImageView.userInteractionEnabled = true
        causingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(activity: Activity) {
        if self.activity != activity {
            causingImageView.setImageWithURLString(ImageURL(activity.activityResourceFollow!.causingPerson.avatarAssetID, width: 40, height: 40))
        }
        
        super.update(activity)
    }
    
    func pushProfile() {
        navigationController?.pushViewController(ProfileTableViewController(personID: activity.activityResourceFollow!.causingPerson.ID), animated: true)
    }
    
}