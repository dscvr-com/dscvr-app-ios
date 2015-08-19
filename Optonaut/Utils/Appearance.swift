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


let BaseColor = UIColor(0xef4836)

func setTabBarIcon(tabBarItem: UITabBarItem, icon: Icomoon) {
    tabBarItem.title = String.icomoonWithName(icon)
}