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
        styleTabBarItem(tabBarItem, .User)
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
        
        let attributes = [NSFontAttributeName: UIFont.icomoonOfSize(20)] as Dictionary!
        let signoutButton = UIBarButtonItem()
        signoutButton.setTitleTextAttributes(attributes, forState: .Normal)
        signoutButton.title = String.icomoonWithName(.Cross)
        signoutButton.target = self
        signoutButton.action = "logout"
        profileVC.navigationItem.setRightBarButtonItem(signoutButton, animated: false)
        
        pushViewController(profileVC, animated: false)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func logout() {
        let refreshAlert = UIAlertController(title: "You're about to log out...", message: "Really? Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Sign out", style: .Default, handler: { (action: UIAlertAction!) in
            NSUserDefaults.standardUserDefaults().setObject("", forKey: UserDefaultsKeys.USER_TOKEN.rawValue)
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: UserDefaultsKeys.USER_IS_LOGGED_IN.rawValue)
            self.presentViewController(LoginViewController(), animated: false, completion: nil)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { _ in return }))
        
        presentViewController(refreshAlert, animated: true, completion: nil)
    }
    
}

