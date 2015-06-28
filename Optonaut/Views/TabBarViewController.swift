//
//  TabBarViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

class TabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let feedVC = FeedNavViewController()
        let searchVC = SearchNavViewController()
        let activityVC = ActivityNavViewController()
        let profileVC = ProfileNavViewController()
        
        viewControllers = [feedVC, searchVC, activityVC, profileVC]
        
//        selectedIndex = 1
        
        tabBar.barTintColor = baseColor()
        tabBar.translucent = false
        
        let tabBarItemAppearance = UITabBarItem.appearance()
        let normalAttribues = [
            NSFontAttributeName: UIFont.fontAwesomeOfSize(25),
            NSForegroundColorAttributeName: UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        ]
        let selectedAttribues = [
            NSFontAttributeName: UIFont.fontAwesomeOfSize(25),
            NSForegroundColorAttributeName: UIColor.whiteColor()
        ]
        
        tabBarItemAppearance.setTitleTextAttributes(normalAttribues, forState: .Normal)
        tabBarItemAppearance.setTitleTextAttributes(selectedAttribues, forState: .Selected)
        tabBarItemAppearance.setTitlePositionAdjustment(UIOffsetMake(0, -10))
        
    }
    
}