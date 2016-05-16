//
//  LoginNavViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 5/16/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class LoginNavViewController: NavigationController {
    
    let viewController = LoginVC()
    
    //weak var parentViewController: UIViewController?
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
