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
import Mixpanel

class ActivityNavViewController: NavigationController, RedNavbar {
    
    let activityTableViewController = ActivityTableViewController()
    
    required init() {
        super.init(nibName: nil, bundle: nil)
//        setTabBarIcon(tabBarItem, icon: .Bell, withFontSize: 20)
        pushViewController(activityTableViewController, animated: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.translucent = false
        navigationBar.barTintColor = UIColor.Accent
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationBar.tintColor = .whiteColor()
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
    }
    
    func initNotificationIndicator() {
        // TODO: simplify
        let tabBar = tabBarController!.tabBar
        let numberOfItems = CGFloat(tabBar.items!.count)
        let tabBarItemSize = CGSize(width: tabBar.frame.width / numberOfItems, height: tabBar.frame.height)
        
        let circle = UILabel()
        circle.frame = CGRect(x: tabBarItemSize.width * 5/2 + 8, y: tabBarItemSize.height / 2 - 18, width: 14, height: 14)
        circle.backgroundColor = .whiteColor()
        circle.font = UIFont.displayOfSize(9, withType: .Regular)
        circle.textAlignment = .Center
        circle.textColor = .Accent
        circle.layer.cornerRadius = 8
        circle.clipsToBounds = true
        circle.hidden = true
        tabBar.addSubview(circle)
        
        activityTableViewController.viewModel.unreadCount.producer.startWithNext { count in
            let hidden = count <= 0
            circle.hidden = hidden
            circle.text = "\(count)"
        }
    }
}
