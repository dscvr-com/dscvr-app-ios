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
        
        
        let loginOverlayViewController = LoginOverlayViewController()
        navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20)!]
        
        if SessionService.isLoggedIn {
            viewControllers.insert(loginOverlayViewController, atIndex: 0)
            pushViewController(ProfileCollectionViewController(personID: SessionService.personID), animated: false)
            if !Defaults[.SessionEliteUser] {
                let gate = InvitationViewController()
                gate.fromProfilePage = true
                pushViewController(gate, animated: false)
            }
            
        } else {
            pushViewController(loginOverlayViewController, animated: false)
            SessionService.loginNotifiaction.signal.observeNext {
                let profilePage = ProfileCollectionViewController(personID: SessionService.personID)
                profilePage.fromLoginPage = true
                self.pushViewController(profilePage, animated: false)
                
                if !Defaults[.SessionEliteUser] {
                    let gate = InvitationViewController()
                    gate.fromProfilePage = true
                    self.pushViewController(gate, animated: false)
                }
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

