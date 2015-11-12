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
        
        causingImageView.image = UIImage.emoji("🌟", fontSize: 24)
        causingImageView.contentMode = .Center
        
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
        if self.activity != activity {
            optographImageView.setImageWithURLString(ImageURL(activity.activityResourceViews!.optograph.previewAssetID, width: 32, height: 40))
        }
        
        super.update(activity)
    }
    
    func pushDetails() {
        navigationController?.pushViewController(DetailsTableViewController(optographID: activity.activityResourceViews!.optograph.ID), animated: true)
    }
    
}

private extension UIImage {
    static func emoji(str: String, fontSize: CGFloat) -> UIImage {
        let attributes = [
            NSFontAttributeName: UIFont.iconOfSize(fontSize),
        ]
        let attributedString = NSAttributedString(string: str, attributes: attributes)
        let size = sizeOfAttributeString(attributedString)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        attributedString.drawInRect(CGRect(origin: CGPointZero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

private func sizeOfAttributeString(str: NSAttributedString) -> CGSize {
    return str.boundingRectWithSize(CGSizeMake(10000, 10000), options:(NSStringDrawingOptions.UsesLineFragmentOrigin), context:nil).size
}