//
//  ViewWithDiagonalLine.swift
//  DSCVR
//
//  Created by Thadz on 04/10/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import Foundation

class ViewWithDiagonalLine: UIView {
    
    private let line: UIView
    
    private var lengthConstraint: NSLayoutConstraint!
    
    init() {
        // Initialize line view
        line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = UIColor.blackColor()
        
        super.init(frame: CGRectZero)
        
        clipsToBounds = true // Cut off everything outside the view
        
        // Add and layout the line view
        
        addSubview(line)
        
        // Define line width
        line.addConstraint(NSLayoutConstraint(item: line, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 1))
        
        // Set up line length constraint
        lengthConstraint = NSLayoutConstraint(item: line, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 0)
        addConstraint(lengthConstraint)
        
        // Center line in view
        addConstraint(NSLayoutConstraint(item: line, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: line, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update length constraint and rotation angle
        lengthConstraint.constant = sqrt(pow(frame.size.width, 2) + pow(frame.size.height, 2))
        line.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) - atan2(frame.size.height, frame.size.width))
//        line.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
    }
    
}
