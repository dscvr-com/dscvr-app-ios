//
//  ActivityCommentTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

class ActivityCommentTableViewCell: ActivityTableViewCell {
    
    private let optographImageView = PlaceholderImageView()
    
    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        causingImageView.userInteractionEnabled = true
        causingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ActivityCommentTableViewCell.pushProfile)))
        
        optographImageView.userInteractionEnabled = true
        optographImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ActivityCommentTableViewCell.pushDetails)))
        optographImageView.contentMode = .ScaleAspectFill
        contentView.addSubview(optographImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        
        optographImageView.autoAlignAxisToSuperviewAxis(.Horizontal)
        optographImageView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -20)
        optographImageView.autoSetDimensionsToSize(CGSize(width: 32, height: 40))
        
        super.updateConstraints()
    }
    
    override func update(activity: Activity) {
        if self.activity != activity {
            causingImageView.setImageWithURLString(ImageURL(activity.activityResourceComment!.causingPerson.avatarAssetID, width: 40, height: 40))
        }
        
        if self.activity != activity {
//            optographImageView.setImageWithURLString(ImageURL(activity.activityResourceComment!.optograph.previewAssetID, width: 32, height: 40))
        }
        
        super.update(activity)
    }
    
    func pushProfile() {
//        navigationController?.pushViewController(ProfileTableViewController(personID: activity.activityResourceComment!.causingPerson.ID), animated: true)
    }
    
    func pushDetails() {
//        navigationController?.pushViewController(DetailsTableViewController(optographID: activity.activityResourceComment!.optograph.ID), animated: true)
    }
    
}