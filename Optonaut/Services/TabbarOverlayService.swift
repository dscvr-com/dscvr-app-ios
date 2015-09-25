//
//  UIOverlayService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/23/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class TabbarOverlayService {
    
    static var tabBarHeight: CGFloat = 0
    
    static let layer = TabbarOverlayLayer()
    
    private static let gradientHeight: CGFloat = 25
    
    static var hidden: Bool = false {
        didSet {
            layer.hidden = hidden
        }
    }
    
    static var contentOffsetTop: CGFloat = 0 {
        didSet {
            scrollOffsetTop = scrollOffsetTop + 0
        }
    }
    
    static var scrollOffsetTop: CGFloat = 0 {
        didSet {
            let y = 20 + contentOffsetTop
            let height = max(0, min(gradientHeight, scrollOffsetTop))
            layer.topGradientLayer.opacity = Float(height / gradientHeight)
            layer.topGradientLayer.frame = CGRect(x: 0, y: y, width: layer.frame.width, height: height)
        }
    }
    
    static var scrollOffsetBottom: CGFloat = 0 {
        didSet {
            let height = max(0, min(gradientHeight, scrollOffsetBottom))
            let y = layer.frame.height - tabBarHeight - height
            layer.bottomGradientLayer.opacity = Float(height / gradientHeight)
            layer.bottomGradientLayer.frame = CGRect(x: 0, y: y, width: layer.frame.width, height: height)
        }
    }
    
}

class TabbarOverlayLayer: CALayer {
    
    let statusBarLayer = CALayer()
    let topGradientLayer = CAGradientLayer()
    let bottomGradientLayer = CAGradientLayer()
    
    override init() {
        super.init()
        postInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func postInit() {
        statusBarLayer.backgroundColor = UIColor.blackColor().CGColor
        addSublayer(statusBarLayer)
        
        topGradientLayer.colors = [UIColor(white: 0, alpha: 1).CGColor, UIColor(white: 0, alpha: 0).CGColor]
        topGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        topGradientLayer.endPoint = CGPoint(x: 0, y: 1)
        addSublayer(topGradientLayer)
        
        bottomGradientLayer.colors = [UIColor(white: 0, alpha: 0).CGColor, UIColor(white: 0, alpha: 1).CGColor]
        bottomGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        bottomGradientLayer.endPoint = CGPoint(x: 0, y: 1)
//        addSublayer(bottomGradientLayer)
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        statusBarLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: 20)
    }
    
}