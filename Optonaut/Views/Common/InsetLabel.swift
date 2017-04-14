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
    
    var edgeInsets: UIEdgeInsets = UIEdgeInsets.zero
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var rect = edgeInsets.apply(bounds)
        rect = super.textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)
        return edgeInsets.inverse.apply(rect)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: edgeInsets.apply(rect))
    }
    
}
