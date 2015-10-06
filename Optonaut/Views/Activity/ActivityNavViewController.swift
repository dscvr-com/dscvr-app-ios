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
        setTabBarIcon(tabBarItem, icon: .Bell)
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
        
        pushViewController(activityTableViewController, animated: false)
        
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
        
        let circle = CALayer()
        circle.frame = CGRect(x: tabBarItemSize.width * 5/2 + 9, y: tabBarController!.view.frame.height - tabBarItemSize.height / 2 - 17, width: 15, height: 15)
        circle.backgroundColor = UIColor.whiteColor().CGColor
        circle.cornerRadius = 7.5
        circle.opacity = 0.6
        circle.hidden = true
        tabBarController!.view.layer.addSublayer(circle)
        
        let number = UILabel()
        number.frame = CGRect(x: tabBarItemSize.width * 5/2 + 9, y: tabBarController!.view.frame.height - tabBarItemSize.height / 2 - 17, width: 15, height: 15)
        number.textAlignment = .Center
        number.text = "5"
        number.textColor = UIColor.Accent
        number.font = UIFont.robotoOfSize(9, withType: .Black)
        number.hidden = true
        tabBarController!.view.addSubview(number)
        
        activityTableViewController.viewModel.unreadCount.producer.startWithNext { count in
            let hidden = count <= 0
            circle.hidden = hidden
            number.hidden = hidden
            number.text = "\(count)"
        }
    }
}
