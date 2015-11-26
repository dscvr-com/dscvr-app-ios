//
//  BoundingButton.swift
//  Optonaut
//
//  Created by Johannes Schickling on 26/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class BoundingButton: UIButton {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let margin: CGFloat = 5
        let area = CGRectInset(bounds, -margin, -margin)
        return CGRectContainsPoint(area, point)
    }
}