//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

import UIKit
import FontAwesome
import ReactiveCocoa

class ActivityNavViewController: UINavigationController {
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        styleTabBarItem(tabBarItem, FontAwesome.Heartbeat)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.translucent = false
        navigationBar.barTintColor = baseColor()
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationBar.tintColor = .whiteColor()
        
        let activityTableViewController = ActivityTableViewController()
        
        pushViewController(activityTableViewController, animated: false)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
}
