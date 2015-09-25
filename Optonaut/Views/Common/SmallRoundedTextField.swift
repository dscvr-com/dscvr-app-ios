//
//  SmallRoundedTextField.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/23/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import HexColor

class SmallRoundedTextField: UITextField {
    
    private let lineLayer = CAShapeLayer()
    
    private var isEditing = false
    
    override var placeholder: String? {
        didSet {
            updatePlaceholder()
        }
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        postInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func postInit() {
        borderStyle = .None
        backgroundColor = .clearColor()
        clipsToBounds = false
        
        textAlignment = .Left
        font = UIFont.robotoOfSize(12, withType: .Regular)
        textColor = .whiteColor()
        
        addTarget(self, action: "beginEditing", forControlEvents: .EditingDidBegin)
        addTarget(self, action: "endEditing", forControlEvents: .EditingDidEnd)
        
        lineLayer.lineWidth = 1
        lineLayer.strokeColor = UIColor.Accent.CGColor
        lineLayer.fillColor = UIColor.clearColor().CGColor
        layer.addSublayer(lineLayer)
    }
    
    private func updatePlaceholder() {
        let attributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor().alpha(0.5),
            NSFontAttributeName: UIFont.robotoOfSize(12, withType: .Regular),
        ]
        attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: attributes)
    }
    
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x + 5, y: bounds.origin.y, width: bounds.width - 10, height: bounds.height)
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return textRectForBounds(bounds)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        frame = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: 30))
        
        let linePath = UIBezierPath()
        linePath.addArcWithCenter(CGPoint(x: 5, y: 0), radius: 5, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI_2), clockwise: false)
        linePath.addLineToPoint(CGPoint(x: frame.width - 5, y: 5))
        linePath.addArcWithCenter(CGPoint(x: frame.width - 5, y: 0), radius: 5, startAngle: CGFloat(M_PI_2), endAngle: 0, clockwise: false)
        lineLayer.path = linePath.CGPath
        lineLayer.frame = CGRect(x: 0, y: 25, width: frame.width, height: 5)
    }
    
    func beginEditing() {
        isEditing = true
    }
    
    func endEditing() {
        isEditing = false
    }
    
}