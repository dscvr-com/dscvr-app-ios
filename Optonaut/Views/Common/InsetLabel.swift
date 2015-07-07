//
//  InsetLabel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/7/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

class InsetLabel: UILabel {
    
    var edgeInsets: UIEdgeInsets = UIEdgeInsetsZero
    
    override func textRectForBounds(bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var rect = edgeInsets.apply(bounds)
        rect = super.textRectForBounds(rect, limitedToNumberOfLines: numberOfLines)
        return edgeInsets.inverse.apply(rect)
    }
    
    override func drawTextInRect(rect: CGRect) {
        super.drawTextInRect(edgeInsets.apply(rect))
    }
    
}