//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class ProfileNavViewController: UINavigationController {
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        styleTabBarItem(tabBarItem, icon: .User)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.translucent = true
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics:UIBarMetrics.Default)
        navigationBar.shadowImage = UIImage()
        navigationBar.tintColor = .whiteColor() // needed for back button on details
        
        let userId = NSUserDefaults.standardUserDefaults().integerForKey(UserDefaultsKeys.UserId.rawValue);
        let profileVC = ProfileViewController(userId: userId)
        
        pushViewController(profileVC, animated: false)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
}

