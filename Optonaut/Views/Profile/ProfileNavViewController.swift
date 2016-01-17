//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class ProfileNavViewController: NavigationController {
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        setTabBarIcon(tabBarItem, icon: .Cancel, withFontSize: 20)
        // TODO
        if SessionService.isLoggedIn {
            pushViewController(ProfileTableViewController(personID: Defaults[.SessionPersonID]!), animated: false)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
}

