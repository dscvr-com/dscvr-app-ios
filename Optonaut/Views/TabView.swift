//
//  TabView.swift
//  Iam360
//
//  Created by robert john alkuino on 5/7/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class TabView: UIView {

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
        
        //cameraButton.frame = CGRect(x: frame.width / 2 - 35, y: 126 / 2 - 35, width: 80, height: 80)
        cameraButton.icon = UIImage(named:"camera_icn")!
        cameraButton.anchorToEdge(.Bottom, padding: 20, width: 80, height: 80)
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
