//
//  BackgroundView.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/6/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class BackgroundView: UIView {
    
    fileprivate let line = CAShapeLayer()
    fileprivate let background = CALayer()
    fileprivate let circle = CAShapeLayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        line.strokeColor = UIColor.LightGrey.cgColor
        line.fillColor = UIColor.clear.cgColor
        line.lineWidth = 1
        layer.addSublayer(line)
        
        background.backgroundColor = UIColor(0xF9F9F9).cgColor
        layer.addSublayer(background)
        
        circle.strokeColor = UIColor.LightGrey.cgColor
        circle.fillColor = UIColor.white.cgColor
        circle.lineWidth = 1
        layer.addSublayer(circle)
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 0, y: 5.5))
        linePath.addLine(to: CGPoint(x: frame.width, y: 5.5))
        line.path = linePath.cgPath
        line.frame = bounds
        
        background.frame = CGRect(x: 0, y: 6.5, width: frame.width, height: frame.height - 6.5)
        
        let circlePath = UIBezierPath()
        circlePath.addArc(withCenter: CGPoint(x: frame.width / 2, y: 5.5), radius: 4.5, startAngle: 0, endAngle: CGFloat(M_PI * 2), clockwise: true)
        circle.path = circlePath.cgPath
        circle.frame = bounds
    }
}
