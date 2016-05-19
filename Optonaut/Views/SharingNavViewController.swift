//
//  SharingNavViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 5/12/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class SharingNavViewController: NavigationController {

    
    let viewController = SharingViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewController.navigationItem.title = "Share"
        
        navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Avenir-Book", size: 20)!]
        pushViewController(viewController, animated: false)
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
