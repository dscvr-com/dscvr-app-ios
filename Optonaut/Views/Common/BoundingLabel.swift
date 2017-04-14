//
//  Label.swift
//  Optonaut
//
//  Created by Johannes Schickling on 26/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class BoundingLabel: UILabel {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let margin: CGFloat = 5
        let area = bounds.insetBy(dx: -margin, dy: -margin)
        return area.contains(point)
    }
}
