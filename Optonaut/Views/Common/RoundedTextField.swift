//
//  RoundedTextField.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/18/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import HexColor

enum MessageType {
    case Success(String)
    case Warning(String)
    case Nil
}

class RoundedTextField: UITextField {
    
    private let lineLayer = CAShapeLayer()
    private let backgroundLayer = CALayer()
    private let messageView = UILabel()
    
    var indicated = false {
        didSet {
            backgroundLayer.backgroundColor = indicated ? UIColor.LightGrey.hatched1.CGColor : UIColor.clearColor().CGColor
            lineLayer.strokeColor = indicated ? UIColor.Accent.CGColor : UIColor.Grey.CGColor
            updatePlaceholder()
        }
    }
    
    var message: MessageType = .Nil {
        didSet {
            switch message {
            case .Warning(let str):
                messageView.text = str
                messageView.textColor = .Accent
            case .Success(let str):
                messageView.text = str
                messageView.textColor = .Success
            case .Nil:
                messageView.text = ""
            }
        }
    }
    
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
        
        textAlignment = .Center
        font = UIFont.robotoOfSize(16, withType: .Regular)
        textColor = .DarkGrey
        
        addTarget(self, action: "beginEditing", forControlEvents: .EditingDidBegin)
        addTarget(self, action: "endEditing", forControlEvents: .EditingDidEnd)
        
        messageView.textAlignment = .Center
        messageView.font = UIFont.robotoOfSize(12, withType: .Regular)
        addSubview(messageView)
        
        backgroundLayer.backgroundColor = UIColor.clearColor().CGColor
        backgroundLayer.cornerRadius = 5
        layer.addSublayer(backgroundLayer)
        
        lineLayer.lineWidth = 1
        lineLayer.strokeColor = UIColor.Grey.CGColor
        lineLayer.fillColor = UIColor.clearColor().CGColor
        layer.addSublayer(lineLayer)
    }
    
    private func updatePlaceholder() {
        let attributes = [
            NSForegroundColorAttributeName: indicated ? UIColor.Accent : UIColor.Grey,
            NSFontAttributeName: UIFont.robotoOfSize(16, withType: .Regular),
        ]
        attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: attributes)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        frame = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: 50))
        
        backgroundLayer.frame = CGRect(origin: CGPointZero, size: CGSize(width: frame.width, height: 50))
        
        let linePath = UIBezierPath()
        linePath.addArcWithCenter(CGPoint(x: 5, y: 0), radius: 5, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI_2), clockwise: false)
        linePath.addLineToPoint(CGPoint(x: frame.width - 5, y: 5))
        linePath.addArcWithCenter(CGPoint(x: frame.width - 5, y: 0), radius: 5, startAngle: CGFloat(M_PI_2), endAngle: 0, clockwise: false)
        lineLayer.path = linePath.CGPath
        lineLayer.frame = CGRect(x: 0, y: 45, width: frame.width, height: 5)
        
        messageView.frame = CGRect(x: 0, y: 58, width: frame.width, height: 15)
    }
    
    func beginEditing() {
        lineLayer.strokeColor = UIColor.Accent.CGColor
    }
    
    func endEditing() {
        lineLayer.strokeColor = UIColor.LightGrey.CGColor
    }
    
}