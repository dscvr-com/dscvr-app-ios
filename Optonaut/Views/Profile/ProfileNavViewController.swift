//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import FontAwesome

class ProfileNavViewController: UINavigationController {
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        styleTabBarItem(tabBarItem, FontAwesome.User)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.translucent = false
        navigationBar.barTintColor = baseColor()
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationBar.tintColor = .whiteColor()
        
        let userId = NSUserDefaults.standardUserDefaults().integerForKey(UserDefaultsKeys.USER_ID.rawValue);
        let profileVC = ProfileViewController(userId: userId)
        
        pushViewController(profileVC, animated: false)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
}

