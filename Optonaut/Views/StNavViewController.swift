//
//  StNavViewController.swift
//  DSCVR
//
//  Created by robert john alkuino on 8/24/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class StNavViewController: NavigationController {
    
    //change view controller to something with a login
//    let viewController = StorytellingCollectionViewController(personID: SessionService.personID)
    
    required init(){
        super.init(nibName: nil, bundle: nil)
        
        let stVC = UIViewController()
        stVC.view.backgroundColor = UIColor.blackColor()
        
        navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20)!]
        
        if SessionService.isLoggedIn {
            viewControllers.insert(stVC, atIndex: 0)
            pushViewController(StorytellingCollectionViewController(personID: SessionService.personID), animated: false)
            
        } else {
            pushViewController(stVC, animated: false)
            SessionService.loginNotifiaction.signal.observeNext {
                let profilePage = StorytellingCollectionViewController(personID: SessionService.personID)
                profilePage.fromLoginPage = true
                self.pushViewController(profilePage, animated: false)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }

}
