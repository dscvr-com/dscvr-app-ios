//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

import UIKit
import ReactiveCocoa

class ActivityNavViewController: UINavigationController, RedNavbar {
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        setTabBarIcon(tabBarItem, icon: .Bell)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.translucent = false
        navigationBar.barTintColor = BaseColor
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationBar.tintColor = .whiteColor()
        
        let activityTableViewController = ActivityTableViewController()
        
        pushViewController(activityTableViewController, animated: false)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
    }
    
}
