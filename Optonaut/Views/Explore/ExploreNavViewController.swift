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

class ExploreNavViewController: UINavigationController, RedNavbar {
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        setTabBarIcon(tabBarItem, icon: .Compass)
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
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics:UIBarMetrics.Default)
        
        pushViewController(ExploreTableViewController(), animated: false)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
}