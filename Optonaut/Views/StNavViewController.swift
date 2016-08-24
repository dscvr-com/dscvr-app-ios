//
//  StNavViewController.swift
//  DSCVR
//
//  Created by robert john alkuino on 8/24/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class StNavViewController: NavigationController {
    
    let viewController = StorytellingCollectionViewController(personID: SessionService.personID)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewController.navigationItem.title = "Story"
        
        navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20)!]
        
        navigationBarHidden = false
        navigationBar.translucent = false
        navigationBar.barTintColor = UIColor.whiteColor()
        
        pushViewController(viewController, animated: true)

        // Do any additional setup after loading the view.
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
