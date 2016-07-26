//
//  TabView.swift
//  Iam360
//
//  Created by robert john alkuino on 5/7/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa


class TabView: PTView {

    private let indicatedSideLayer = CALayer()
    
    let cameraButton = RecButton()  
    let leftButton = TButton()
    let rightButton = TButton()
    
    
    private let bottomGradient = CAGradientLayer()
    
    let bottomGradientOffset = MutableProperty<CGFloat>(126)
    
    override init (frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        let width = frame.width
        
        bottomGradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().alpha(0.5).CGColor]
        layer.addSublayer(bottomGradient)
        
        bottomGradientOffset.producer.startWithNext { [weak self] offset in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self?.bottomGradient.frame = CGRect(x: 0, y: 0, width: width, height: offset)
            CATransaction.commit()
        }
        cameraButton.icon = UIImage(named:"camera_icn")!
        let size = UIImage(named:"camera_icn")!.size
        cameraButton.anchorToEdge(.Bottom, padding: 20, width: size.width, height: size.height)
        addSubview(cameraButton)
        
        
        //let buttonSpacing = (frame.width / 2 - 35) / 2 - 40
        //leftButton.frame = CGRect(x: buttonSpacing, y: 126 / 2 - 12, width: 35, height: 35)
        leftButton.icon = UIImage(named:"photo_library_icn")!
        addSubview(leftButton)
        leftButton.anchorInCorner(.BottomLeft, xPad: 20, yPad: 20, width: 35, height: 35)
        
        //rightButton.frame = CGRect(x: frame.width - buttonSpacing - 28, y: 126 / 2 - 12, width: 35, height: 35)
        rightButton.icon = UIImage(named:"settings_icn")!
        rightButton.anchorInCorner(.BottomRight, xPad: 20, yPad: 20, width: 35, height: 35)
        addSubview(rightButton)
    }

}

class PTView: UIView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.hidden && subview.alpha > 0 && subview.userInteractionEnabled && subview.pointInside(convertPoint(point, toView: subview), withEvent: event) {
                return true
            }
        }
        return false
    }
}

struct SamplePaths {
    static func cameraPath() -> CGPath {
        let fillColor = UIColor(red: 0.991, green: 0.777, blue: 0.292, alpha: 1.000)
        
        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.moveToPoint(CGPoint(x: 38, y: -0.2))
        bezierPath.addCurveToPoint(CGPoint(x: -0.2, y: 38), controlPoint1: CGPoint(x: 16.9, y: -0.2), controlPoint2: CGPoint(x: -0.2, y: 16.9))
        bezierPath.addCurveToPoint(CGPoint(x: 38, y: 76.2), controlPoint1: CGPoint(x: -0.2, y: 59.1), controlPoint2: CGPoint(x: 16.9, y: 76.2))
        bezierPath.addCurveToPoint(CGPoint(x: 76.2, y: 38), controlPoint1: CGPoint(x: 59.1, y: 76.2), controlPoint2: CGPoint(x: 76.2, y: 59.1))
        bezierPath.addCurveToPoint(CGPoint(x: 38, y: -0.2), controlPoint1: CGPoint(x: 76.2, y: 16.9), controlPoint2: CGPoint(x: 59.1, y: -0.2))
        bezierPath.closePath()
        bezierPath.moveToPoint(CGPoint(x: 61, y: 50.1))
        bezierPath.addCurveToPoint(CGPoint(x: 54.6, y: 57), controlPoint1: CGPoint(x: 61, y: 53.6), controlPoint2: CGPoint(x: 58.1, y: 57))
        bezierPath.addLineToPoint(CGPoint(x: 21.3, y: 57))
        bezierPath.addCurveToPoint(CGPoint(x: 14.9, y: 50.1), controlPoint1: CGPoint(x: 17.8, y: 57), controlPoint2: CGPoint(x: 14.9, y: 53.6))
        bezierPath.addLineToPoint(CGPoint(x: 14.9, y: 32.5))
        bezierPath.addCurveToPoint(CGPoint(x: 21.3, y: 26), controlPoint1: CGPoint(x: 14.9, y: 29), controlPoint2: CGPoint(x: 17.8, y: 26))
        bezierPath.addLineToPoint(CGPoint(x: 26.9, y: 26))
        bezierPath.addLineToPoint(CGPoint(x: 26.9, y: 25.8))
        bezierPath.addCurveToPoint(CGPoint(x: 32.8, y: 19), controlPoint1: CGPoint(x: 26.9, y: 22.3), controlPoint2: CGPoint(x: 29.3, y: 19))
        bezierPath.addLineToPoint(CGPoint(x: 43, y: 19))
        bezierPath.addCurveToPoint(CGPoint(x: 48.9, y: 25.8), controlPoint1: CGPoint(x: 46.5, y: 19), controlPoint2: CGPoint(x: 48.9, y: 22.3))
        bezierPath.addLineToPoint(CGPoint(x: 48.9, y: 26))
        bezierPath.addLineToPoint(CGPoint(x: 54.5, y: 26))
        bezierPath.addCurveToPoint(CGPoint(x: 60.9, y: 32.5), controlPoint1: CGPoint(x: 58, y: 26), controlPoint2: CGPoint(x: 60.9, y: 29))
        bezierPath.addLineToPoint(CGPoint(x: 60.9, y: 50.1))
        bezierPath.addLineToPoint(CGPoint(x: 61, y: 50.1))
        bezierPath.closePath()
        bezierPath.miterLimit = 4;
        
        fillColor.setFill()
        bezierPath.fill()
        
        return bezierPath.CGPath
        
    }
}
