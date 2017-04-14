//
//  LineTextField.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/18/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

class LineTextField: UITextField {
    
    static var i = 0

    enum Status: Equatable {
        case normal
        case disabled
        case indicated
        case warning(String)
    }
    
    enum Size: CGFloat {
        case large = 18
        case medium = 14
        case small = 13
    }
    
    enum Color {
        case light
        case dark
    }
    
    var color: Color = .dark {
        didSet {
            update()
        }
    }
    
    var size: Size = .medium {
        didSet {
            layoutSubviews()
        }
    }
    
    var status: Status = .normal {
        didSet {
            update()
        }
    }
    
    override var placeholder: String? {
        didSet {
            update()
        }
    }
    
    var previousText: String?
    
    override var text: String? {
        didSet {
            previousText = oldValue
        }
    }
    
    override var attributedText: NSAttributedString? {
        didSet {
//            previousText = oldValue
        }
    }
    
    fileprivate let lineLayer = CALayer()
    fileprivate let messageView = UILabel()
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        postInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func postInit() {
        borderStyle = .none
        backgroundColor = .clear
        clipsToBounds = false
        textAlignment = .left
        contentVerticalAlignment = .top
        
        update()
        
        addTarget(self, action: "beginEditing", for: .editingDidBegin)
        addTarget(self, action: "changed", for: .editingChanged)
        addTarget(self, action: "endEditing", for: .editingDidEnd)
        
        messageView.textAlignment = .right
        addSubview(messageView)
        
        lineLayer.backgroundColor = UIColor.white.cgColor
        layer.addSublayer(lineLayer)
    }
    
    fileprivate func update() {
        let baseColor: UIColor = {
            switch self.color {
            case .light: return UIColor.white
            case .dark: return UIColor.DarkGrey
            }
        }()
        
        let baseFontSize = size.rawValue
        
        // placeholder
        var attributes: [String: AnyObject] = [
            NSFontAttributeName: UIFont.textOfSize(baseFontSize, withType: .Regular)
        ]
        switch status {
        case .disabled: attributes[NSForegroundColorAttributeName] = baseColor.alpha(0.15)
        default: attributes[NSForegroundColorAttributeName] = baseColor.alpha(0.4)
        }
        attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: attributes)
        
        font = UIFont.textOfSize(baseFontSize, withType: .Regular)
        
        // text field
        textColor = baseColor
        if case .disabled = status {
            isUserInteractionEnabled = false
        } else {
            isUserInteractionEnabled = true
        }
        
        // line color
        if case .light = color {
            switch status {
            case .disabled: lineLayer.backgroundColor = baseColor.alpha(0.15).cgColor
            case .indicated: lineLayer.backgroundColor = baseColor.alpha(0.7).cgColor
            default: lineLayer.backgroundColor = baseColor.alpha(1).cgColor
            }
        } else {
            switch status {
            case .disabled: lineLayer.backgroundColor = baseColor.alpha(0.15).cgColor
            case .indicated: lineLayer.backgroundColor = UIColor.Accent.cgColor
            default: lineLayer.backgroundColor = baseColor.alpha(1).cgColor
            }
        }
        
        // message
        if case .light = color {
            messageView.textColor = baseColor
        } else {
            messageView.textColor = baseColor
        }
        messageView.font = UIFont.displayOfSize(10, withType: .Regular)
        if case .warning(let message) = status {
            messageView.text = message
        } else {
            messageView.text = ""
        }
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let onePx = 1 / UIScreen.main.scale
        
        switch size {
        case .large:
            frame = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: 51))
            lineLayer.frame = CGRect(x: 0, y: 34, width: frame.width, height: onePx)
            messageView.frame = CGRect(x: 0, y: 36, width: frame.width, height: 15)
        case .medium:
            frame = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: 43))
            lineLayer.frame = CGRect(x: 0, y: 28, width: frame.width, height: onePx)
            messageView.frame = CGRect(x: 0, y: 30, width: frame.width, height: 15)
        case .small:
            frame = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: 41))
            lineLayer.frame = CGRect(x: 0, y: 24, width: frame.width, height: onePx)
            messageView.frame = CGRect(x: 0, y: 26, width: frame.width, height: 15)
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let margin: CGFloat = 5
        let area = bounds.insetBy(dx: -margin, dy: -margin)
        return area.contains(point)
    }
    
    func beginEditing() {
        update()
    }
    
    func endEditing() {
        update()
    }
    
}

func ==(lhs: LineTextField.Status, rhs: LineTextField.Status) -> Bool {
    switch (lhs, rhs) {
    case let (.warning(lhs), .warning(rhs)): return lhs == rhs
    case (.normal, .normal): return true
    case (.disabled, .disabled): return true
    case (.indicated, .indicated): return true
    default: return false
    }
}
