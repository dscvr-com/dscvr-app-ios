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
        navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.icomoonOfSize(50),
            NSForegroundColorAttributeName: UIColor.whiteColor()
        ]
        navigationBar.tintColor = .whiteColor()
        navigationBar.setTitleVerticalPositionAdjustment(16, forBarMetrics: .Default)
        
        
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics:UIBarMetrics.Default)
        
        let optographTableViewController = OptographTableViewController(source: "optographs", navController: self, fullscreen: true)
        optographTableViewController.navigationItem.title = String.icomoonWithName(.LogoText)
        
        let cameraButton = UIBarButtonItem()
        cameraButton.image = UIImage.icomoonWithName(.Camera, textColor: .whiteColor(), size: CGSize(width: 21, height: 17))
        cameraButton.target = self
        cameraButton.action = "showCamera"
        optographTableViewController.navigationItem.setRightBarButtonItem(cameraButton, animated: false)
        
        let searchButton = UIBarButtonItem()
        searchButton.title = String.icomoonWithName(.MagnifyingGlass)
        searchButton.image = UIImage.icomoonWithName(.MagnifyingGlass, textColor: .whiteColor(), size: CGSize(width: 21, height: 17))
        searchButton.target = self
        searchButton.action = "showSearch"
        optographTableViewController.navigationItem.setLeftBarButtonItem(searchButton, animated: false)
        
        pushViewController(optographTableViewController, animated: false)
    }
    
    func showCamera() {
        pushViewController(CameraViewController(), animated: false)
    }
    
    func showSearch() {
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
}