//
//  Appearance.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/8/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import HexColor
import Icomoon

func setupAppearanceDefaults() {
    UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
    
    UINavigationBar.appearance().tintColor = .whiteColor()
    UINavigationBar.appearance().setBackgroundImage(UIImage(), forBarMetrics: .Default)
    UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont.displayOfSize(20, withType: .Regular)]
    
    let image = UIImage.iconWithName(.Back, textColor: .whiteColor(), fontSize: 18, offset: CGSize(width: 13, height: 0))
    UINavigationBar.appearance().backIndicatorImage = image
    UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -200, vertical: 0), forBarMetrics: .Default)
    UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage()
}

extension UIColor {
    static var Accent: UIColor {
        get {
            return UIColor(0xef4836)
        }
    }
    
    static var DarkGrey: UIColor {
        get {
            return UIColor(0x707070)
        }
    }
    
    static var Grey: UIColor {
        get {
            return UIColor(0xAAAAAA)
        }
    }
    
    static var LightGrey: UIColor {
        get {
            return UIColor(0xDDDDDD)
        }
    }
    
    static var WhiteGrey: UIColor {
        get {
            return UIColor(0xEEEEEE)
        }
    }
    static var Clear: UIColor {
        get {
            return UIColor.clearColor()
        }
    }
    
//    static var LightGreyActive: UIColor {
//        get {
//            return UIColor.blackColor().alpha(0.20)
//        }
//    }
    
    static var Success: UIColor {
        get {
            return UIColor(0x91CB3E)
        }
    }
}

func setTabBarIcon(tabBarItem: UITabBarItem, icon: Icon, withFontSize fontSize: CGFloat) {
    tabBarItem.title = String.iconWithName(icon)
    
    let attribues = [
        NSFontAttributeName: UIFont.iconOfSize(fontSize),
        NSForegroundColorAttributeName: UIColor.whiteColor(),
    ]
    tabBarItem.setTitleTextAttributes(attribues, forState: .Normal)
    tabBarItem.titlePositionAdjustment = UIOffsetMake(0, -13)
}