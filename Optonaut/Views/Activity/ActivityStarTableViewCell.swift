//
//  ActivityStarTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

class ActivityStarTableViewCell: ActivityTableViewCell {
    
    private let optographImageView = PlaceholderImageView()
    
    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        causingImageView.userInteractionEnabled = true
        causingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ActivityStarTableViewCell.pushProfile)))
        
        nameView.userInteractionEnabled = true
        nameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ActivityStarTableViewCell.pushProfile)))
        
        optographImageView.userInteractionEnabled = true
        optographImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ActivityStarTableViewCell.pushDetails)))
        optographImageView.contentMode = .ScaleAspectFill
        optographImageView.backgroundColor = UIColor.grayColor()
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
            
            let imageUrl = ImageURL("persons/\(activity.activityResourceStar!.causingPerson.ID)/\(activity.activityResourceStar!.causingPerson.avatarAssetID).jpg", width: 47, height: 47)
            causingImageView.kf_setImageWithURL(NSURL(string:imageUrl)!)
            
            nameView.text = activity.activityResourceStar!.causingPerson.userName
            
            let url = TextureURL(activity.activityResourceStar!.optograph!.ID, side: .Left, size: frame.width, face: 0, x: 0, y: 0, d: 1)
            self.optographImageView.kf_setImageWithURL(NSURL(string: url)!)
        }
        
        super.update(activity)
    }
    
    func pushProfile() {
        
        self.read()
        let profilepage = ProfileCollectionViewController(personID: self.activity.activityResourceStar!.causingPerson.ID)
        profilepage.isProfileVisit = true
        self.navigationController?.pushViewController(profilepage, animated: true)
    }
    
    func pushDetails() {
        if Models.optographs[self.activity.activityResourceStar!.optograph!.ID] != nil {
            print("wew")
            self.read()
            let detailsViewController = DetailsTableViewController(optoList:[activity.activityResourceStar!.optograph!.ID])
            detailsViewController.cellIndexpath = 0
            navigationController?.pushViewController(detailsViewController, animated: true)
        }
    }
    
}
