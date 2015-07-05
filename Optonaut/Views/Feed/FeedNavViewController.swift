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
        styleTabBarItem(tabBarItem, .Infinity)
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
        
        let optographTableViewController = OptographTableViewController(source: "optographs", navController: self)
        optographTableViewController.navigationItem.title = "Feed"
        
        let attributes = [NSFontAttributeName: UIFont.icomoonOfSize(20)] as Dictionary!
        let cameraButton = UIBarButtonItem()
        cameraButton.setTitleTextAttributes(attributes, forState: .Normal)
        cameraButton.title = String.icomoonWithName(.Camera)
        cameraButton.target = self
        cameraButton.action = "showCamera"
        optographTableViewController.navigationItem.setRightBarButtonItem(cameraButton, animated: false)
        
        pushViewController(optographTableViewController, animated: false)
    }
    
    func showCamera() {
        pushViewController(CameraViewController(), animated: false)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
}
