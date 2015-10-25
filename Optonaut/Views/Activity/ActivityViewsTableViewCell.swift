//
//  ActivityViewsTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

class ActivityViewsTableViewCell: ActivityTableViewCell {
    
    private let optographImageView = PlaceholderImageView()
    
    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        optographImageView.userInteractionEnabled = true
        optographImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushDetails"))
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
        if self.activity == nil || self.activity.activityResourceViews!.optograph.previewAssetURL != activity.activityResourceViews!.optograph.previewAssetURL {
            optographImageView.setImageWithURLString(activity.activityResourceViews!.optograph.previewAssetURL)
        }
        
        super.update(activity)
    }
    
    func pushDetails() {
        navigationController?.pushViewController(DetailsTableViewController(optographID: activity.activityResourceViews!.optograph.ID), animated: true)
    }
    
}