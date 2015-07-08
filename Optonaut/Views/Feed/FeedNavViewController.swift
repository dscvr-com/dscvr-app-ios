//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class FeedNavViewController: UINavigationController {
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        setTabBarIcon(tabBarItem, icon: .Infinity)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pushViewController(FeedTableViewController(), animated: false)
    }
    
}