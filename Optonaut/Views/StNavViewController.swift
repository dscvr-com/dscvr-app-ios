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
        
        let loginOverlayViewController = LoginOverlayViewController()
        navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20)!]
        
        if SessionService.isLoggedIn {
            viewControllers.insert(loginOverlayViewController, atIndex: 0)
            pushViewController(StorytellingCollectionViewController(personID: SessionService.personID), animated: false)
//            if SessionService.needsOnboarding {
//                let username = AddUsernameViewController()
//                pushViewController(username, animated: false)
//            }
            
//            if !Defaults[.SessionEliteUser] {
//                let gate = InvitationViewController()
//                gate.fromProfilePage = true
//                pushViewController(gate, animated: false)
//            }
            
        } else {
            pushViewController(loginOverlayViewController, animated: false)
            SessionService.loginNotifiaction.signal.observeNext {
                let profilePage = StorytellingCollectionViewController(personID: SessionService.personID)
                profilePage.fromLoginPage = true
                self.pushViewController(profilePage, animated: false)
                
//                if SessionService.needsOnboarding {
//                    let username = AddUsernameViewController()
//                    self.pushViewController(username, animated: false)
//                }
//                
//                if !Defaults[.SessionEliteUser] {
//                    let gate = InvitationViewController()
//                    gate.fromProfilePage = true
//                    self.pushViewController(gate, animated: false)
//                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        pushViewController(viewController, animated: true)

        // Do any additional setup after loading the view.
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
