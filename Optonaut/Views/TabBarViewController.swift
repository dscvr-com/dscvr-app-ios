//
//  TabBarViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import SQLite

class TabBarViewController: UITabBarController {
    
    let feedNavViewController = FeedNavViewController()
    let exploreNavViewController = ExploreNavViewController()
//    let activityNavViewController = ActivityNavViewController()
    let profileNavViewController = ProfileNavViewController()
//    let cameraViewController = CameraViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set view controllers
        viewControllers = [
            feedNavViewController,
            exploreNavViewController,
//            activityNavViewController,
            profileNavViewController,
//            cameraViewController,
        ]
        
//        selectedIndex = 2
        
        feedNavViewController.initNotificationIndicator()
//        activityNavViewController.initNotificationIndicator()
        
        // set bar color
        tabBar.barTintColor = .blackColor()
        tabBar.translucent = false
        
        // set font for bar items
        let tabBarItemAppearance = UITabBarItem.appearance()
        let normalAttribues = [
            NSFontAttributeName: UIFont.iconOfSize(30),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
        tabBarItemAppearance.setTitleTextAttributes(normalAttribues, forState: .Normal)
        let selectedAttribues = [
            NSFontAttributeName: UIFont.iconOfSize(30),
            NSForegroundColorAttributeName: UIColor.blackColor(),
        ]
        tabBarItemAppearance.setTitleTextAttributes(selectedAttribues, forState: .Selected)
        tabBarItemAppearance.titlePositionAdjustment = UIOffsetMake(0, -12)
        
        // set darker red as selected background color
        let circleDiameter = tabBar.frame.height - 20
        let tabBarItemSize = CGSize(width: circleDiameter, height: circleDiameter)
        tabBar.selectionIndicatorImage = UIImage.circleImageWithColor(.whiteColor(), size: tabBarItemSize)
        
        // remove default border
        tabBar.frame.size.width = self.view.frame.width + 4
        tabBar.frame.origin.x = -2
        
        TabbarOverlayService.tabBarHeight = tabBar.frame.size.height
        TabbarOverlayService.layer.frame = view.frame
        view.layer.addSublayer(TabbarOverlayService.layer)
    }
    
}

extension UIImage {
    
    class func circleImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSaveGState(ctx)
        CGContextSetFillColorWithColor(ctx, color.CGColor)
        CGContextFillEllipseInRect(ctx, rect)
        CGContextRestoreGState(ctx)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}