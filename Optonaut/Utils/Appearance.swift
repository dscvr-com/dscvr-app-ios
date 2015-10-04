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

func setupAppearanceDefaults() {
    UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
    UINavigationBar.appearance().tintColor = .whiteColor()
    UINavigationBar.appearance().setBackgroundImage(UIImage(), forBarMetrics:UIBarMetrics.Default)
}

extension UIColor {
    static var Accent: UIColor {
        get {
            return UIColor(0xef4836)
        }
    }
    
    static var DarkGrey: UIColor {
        get {
            return UIColor(0x333333)
        }
    }
    
    static var Grey: UIColor {
        get {
            return UIColor.blackColor().alpha(0.25)
        }
    }
    
    static var LightGrey: UIColor {
        get {
            return UIColor.blackColor().alpha(0.10)
        }
    }
    
    static var LightGreyActive: UIColor {
        get {
            return UIColor.blackColor().alpha(0.20)
        }
    }
    
    static var Success: UIColor {
        get {
            return UIColor(0x91CB3E)
        }
    }
}

func setTabBarIcon(tabBarItem: UITabBarItem, icon: Icomoon) {
    tabBarItem.title = String.icomoonWithName(icon)
}