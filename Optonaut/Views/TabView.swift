//
//  TabView.swift
//  Iam360
//
//  Created by robert john alkuino on 5/7/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import ReactiveSwift


class TabView: PTView {

    fileprivate let indicatedSideLayer = CALayer()
    
    let cameraButton = RecordButton()
    
    fileprivate let bottomGradient = CAGradientLayer()
    
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
        
        bottomGradient.colors = [UIColor.clear.cgColor, UIColor.black.alpha(0.5).cgColor]
        layer.addSublayer(bottomGradient)
        
        bottomGradientOffset.producer.startWithValues { [weak self] offset in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self?.bottomGradient.frame = CGRect(x: 0, y: 0, width: width, height: offset)
            CATransaction.commit()
        }
        //cameraButton.icon = UIImage(named:"camera_icn")!
        let size = UIImage(named:"camera_icn")!.size
        cameraButton.anchorToEdge(.bottom, padding: 20, width: size.width, height: size.height)
        addSubview(cameraButton)
    }

}

class PTView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
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
        bezierPath.move(to: CGPoint(x: 38, y: -0.2))
        bezierPath.addCurve(to: CGPoint(x: -0.2, y: 38), controlPoint1: CGPoint(x: 16.9, y: -0.2), controlPoint2: CGPoint(x: -0.2, y: 16.9))
        bezierPath.addCurve(to: CGPoint(x: 38, y: 76.2), controlPoint1: CGPoint(x: -0.2, y: 59.1), controlPoint2: CGPoint(x: 16.9, y: 76.2))
        bezierPath.addCurve(to: CGPoint(x: 76.2, y: 38), controlPoint1: CGPoint(x: 59.1, y: 76.2), controlPoint2: CGPoint(x: 76.2, y: 59.1))
        bezierPath.addCurve(to: CGPoint(x: 38, y: -0.2), controlPoint1: CGPoint(x: 76.2, y: 16.9), controlPoint2: CGPoint(x: 59.1, y: -0.2))
        bezierPath.close()
        bezierPath.move(to: CGPoint(x: 61, y: 50.1))
        bezierPath.addCurve(to: CGPoint(x: 54.6, y: 57), controlPoint1: CGPoint(x: 61, y: 53.6), controlPoint2: CGPoint(x: 58.1, y: 57))
        bezierPath.addLine(to: CGPoint(x: 21.3, y: 57))
        bezierPath.addCurve(to: CGPoint(x: 14.9, y: 50.1), controlPoint1: CGPoint(x: 17.8, y: 57), controlPoint2: CGPoint(x: 14.9, y: 53.6))
        bezierPath.addLine(to: CGPoint(x: 14.9, y: 32.5))
        bezierPath.addCurve(to: CGPoint(x: 21.3, y: 26), controlPoint1: CGPoint(x: 14.9, y: 29), controlPoint2: CGPoint(x: 17.8, y: 26))
        bezierPath.addLine(to: CGPoint(x: 26.9, y: 26))
        bezierPath.addLine(to: CGPoint(x: 26.9, y: 25.8))
        bezierPath.addCurve(to: CGPoint(x: 32.8, y: 19), controlPoint1: CGPoint(x: 26.9, y: 22.3), controlPoint2: CGPoint(x: 29.3, y: 19))
        bezierPath.addLine(to: CGPoint(x: 43, y: 19))
        bezierPath.addCurve(to: CGPoint(x: 48.9, y: 25.8), controlPoint1: CGPoint(x: 46.5, y: 19), controlPoint2: CGPoint(x: 48.9, y: 22.3))
        bezierPath.addLine(to: CGPoint(x: 48.9, y: 26))
        bezierPath.addLine(to: CGPoint(x: 54.5, y: 26))
        bezierPath.addCurve(to: CGPoint(x: 60.9, y: 32.5), controlPoint1: CGPoint(x: 58, y: 26), controlPoint2: CGPoint(x: 60.9, y: 29))
        bezierPath.addLine(to: CGPoint(x: 60.9, y: 50.1))
        bezierPath.addLine(to: CGPoint(x: 61, y: 50.1))
        bezierPath.close()
        bezierPath.miterLimit = 4;
        
        fillColor.setFill()
        bezierPath.fill()
        
        return bezierPath.cgPath
        
    }
}
