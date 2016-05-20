//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class ProfileNavViewController: NavigationController {
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        
        
        let loginOverlayViewController = LoginOverlayViewController()
        navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20)!]
        print(SessionService.isLoggedIn)
        print(SessionService.personID)
        
        if SessionService.isLoggedIn {
            print("session is logged in")
            viewControllers.insert(loginOverlayViewController, atIndex: 0)
            pushViewController(ProfileCollectionViewController(personID: SessionService.personID), animated: false)
        } else {
            print("pumsok dito after reload tab")
            pushViewController(loginOverlayViewController, animated: false)
            SessionService.loginNotifiaction.signal.observeNext {
//               self.popViewControllerAnimated(false)
               self.pushViewController(ProfileCollectionViewController(personID: SessionService.personID), animated: false)
                print("pumasok dito")
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
}

