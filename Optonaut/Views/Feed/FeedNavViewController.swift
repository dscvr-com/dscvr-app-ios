//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class FeedNavViewController: NavigationController {
    
    let feedTableViewController = FeedTableViewController()
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        setTabBarIcon(tabBarItem, icon: .Infinity)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pushViewController(feedTableViewController, animated: false)
    }
    
    func initNotificationIndicator() {
        // TODO: simplify
        let tabBar = tabBarController!.tabBar
        let numberOfItems = CGFloat(tabBar.items!.count)
        let tabBarItemSize = CGSize(width: tabBar.frame.width / numberOfItems, height: tabBar.frame.height)
        
        let circle = CALayer()
        circle.frame = CGRect(x: tabBarItemSize.width / 2 + 13, y: tabBarController!.view.frame.height - tabBarItemSize.height / 2 - 12, width: 6, height: 6)
        circle.backgroundColor = UIColor.whiteColor().CGColor
        circle.cornerRadius = 3
        circle.hidden = true
        tabBarController!.view.layer.addSublayer(circle)
        
        feedTableViewController.viewModel.newResultsAvailable.producer.startWithNext { circle.hidden = !$0 }
    }
    
}