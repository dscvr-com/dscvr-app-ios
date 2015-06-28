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

class SearchNavViewController: UINavigationController {
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        styleTabBarItem(tabBarItem, FontAwesome.Search)
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
        
        let optographTableViewController = SearchTableViewController(navController: self)
        
        pushViewController(optographTableViewController, animated: false)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
}