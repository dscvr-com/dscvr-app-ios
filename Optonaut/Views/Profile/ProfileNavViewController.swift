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
        setTabBarIcon(tabBarItem, icon: .User)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userId = NSUserDefaults.standardUserDefaults().integerForKey(PersonDefaultsKeys.PersonId.rawValue)
        
        pushViewController(ProfileTableViewController(personId: userId), animated: false)
    }
    
}

