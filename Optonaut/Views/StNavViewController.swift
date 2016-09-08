//
//  StNavViewController.swift
//  DSCVR
//
//  Created by robert john alkuino on 8/24/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class StNavViewController: NavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if SessionService.isLoggedIn {
            pushViewController(StorytellingCollectionViewController(personID: SessionService.personID), animated: false)
            
        } else {
            SessionService.loginNotifiaction.signal.observeNext {
                let storyPage = StorytellingCollectionViewController(personID: SessionService.personID)
                self.pushViewController(storyPage, animated: false)
             
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
