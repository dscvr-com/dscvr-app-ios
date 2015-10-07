//
//  BackgroundView.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/6/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import HexColor

class BackgroundView: UIView {
    
    private let line = CAShapeLayer()
    private let background = CALayer()
    private let circle = CAShapeLayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        line.strokeColor = UIColor.LightGrey.CGColor
        line.fillColor = UIColor.clearColor().CGColor
        line.lineWidth = 1
        layer.addSublayer(line)
        
        background.backgroundColor = UIColor(0xF9F9F9).CGColor
        layer.addSublayer(background)
        
        circle.strokeColor = UIColor.LightGrey.CGColor
        circle.fillColor = UIColor.whiteColor().CGColor
        circle.lineWidth = 1
        layer.addSublayer(circle)
    }
    
    convenience init () {
        self.init(frame: CGRectZero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let linePath = UIBezierPath()
        linePath.moveToPoint(CGPoint(x: 0, y: 5.5))
        linePath.addLineToPoint(CGPoint(x: frame.width, y: 5.5))
        line.path = linePath.CGPath
        line.frame = bounds
        
        background.frame = CGRect(x: 0, y: 6.5, width: frame.width, height: frame.height - 6.5)
        
        let circlePath = UIBezierPath()
        circlePath.addArcWithCenter(CGPoint(x: frame.width / 2, y: 5.5), radius: 4.5, startAngle: 0, endAngle: CGFloat(M_PI * 2), clockwise: true)
        circle.path = circlePath.CGPath
        circle.frame = bounds
    }
}