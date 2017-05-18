//
//  Appearance.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/8/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
//import Icomoon

func setupAppearanceDefaults() {
    UIApplication.shared.setStatusBarStyle(.lightContent, animated: false)
    
    UINavigationBar.appearance().tintColor = .white
    UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
    UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont.displayOfSize(20, withType: .Semibold)]
    UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -200, vertical: 0), for: .default)
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
            return UIColor.clear
        }
    }

    static var Success: UIColor {
        get {
            return UIColor(0x91CB3E)
        }
    }
}
