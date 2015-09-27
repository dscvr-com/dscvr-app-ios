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

class RoundedTextField: UITextField {
    
    static var i = 0

    enum Status {
        case Normal
        case Disabled
        case Indicated
        case Warning(String)
    }
    
    enum Size: CGFloat {
        case Large = 21
        case Medium = 14
        case Small = 13
    }
    
    enum Color {
        case Light
        case Dark
    }
    
    var color: Color = .Dark {
        didSet {
            update()
        }
    }
    
    var size: Size = .Medium {
        didSet {
            layoutSubviews()
        }
    }
    
    var status: Status = .Normal {
        didSet {
            update()
        }
    }
    
    override var placeholder: String? {
        didSet {
            update()
        }
    }
    
    private let lineLayer = CALayer()
    private let messageView = UILabel()
    
    private var isEditing = false
    
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
        
        update()
        
        addTarget(self, action: "beginEditing", forControlEvents: .EditingDidBegin)
        addTarget(self, action: "endEditing", forControlEvents: .EditingDidEnd)
        
        messageView.textAlignment = .Right
        addSubview(messageView)
        
        lineLayer.backgroundColor = UIColor.whiteColor().CGColor
        layer.addSublayer(lineLayer)
    }
    
    private func update() {
        let baseColor: UIColor = {
            switch self.color {
            case .Light: return UIColor.whiteColor()
            case .Dark: return UIColor.DarkGrey
            }
        }()
        
        let baseFontSize = size.rawValue
        
        // placeholder
        var attributes: [String: AnyObject] = [
            NSFontAttributeName: UIFont.robotoOfSize(baseFontSize, withType: .Regular)
        ]
        switch status {
        case .Disabled: attributes[NSForegroundColorAttributeName] = baseColor.alpha(0.15)
        default: attributes[NSForegroundColorAttributeName] = baseColor.alpha(0.4)
        }
        attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: attributes)
        
        font = UIFont.textOfSize(baseFontSize, withType: .Regular)
        
        // text field
        textColor = baseColor
        if case .Disabled = status {
            userInteractionEnabled = false
        } else {
            userInteractionEnabled = true
        }
        
        // line color
        if case .Light = color {
            switch status {
            case .Disabled: lineLayer.backgroundColor = baseColor.alpha(0.15).CGColor
            case .Indicated: lineLayer.backgroundColor = baseColor.alpha(0.7).CGColor
            default: lineLayer.backgroundColor = baseColor.alpha(1).CGColor
            }
        } else {
            
        }
        
        // message
        if case .Light = color {
            messageView.textColor = baseColor
        } else {
            
        }
        messageView.font = UIFont.displayOfSize(10, withType: .Regular)
        if case .Warning(let message) = status {
            messageView.text = message
        } else {
            messageView.text = ""
        }
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let onePx = 1 / UIScreen.mainScreen().scale
        
        switch size {
        case .Large:
            frame = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: 21))
            lineLayer.frame = CGRect(x: 0, y: 34, width: frame.width, height: onePx)
            messageView.frame = CGRect(x: 0, y: 36, width: frame.width, height: 15)
        case .Medium:
            break
//            frame = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: 50))
//            lineLayer.frame = CGRect(x: 0, y: 45, width: frame.width, height: 0.5)
//            messageView.frame = CGRect(x: 0, y: 58, width: frame.width, height: 15)
        case .Small:
            break
//            frame = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: 50))
//            lineLayer.frame = CGRect(x: 0, y: 45, width: frame.width, height: 0.5)
//            messageView.frame = CGRect(x: 0, y: 58, width: frame.width, height: 15)
        }
    }
    
    func beginEditing() {
        isEditing = true
        update()
    }
    
    func endEditing() {
        isEditing = false
        update()
    }
    
}