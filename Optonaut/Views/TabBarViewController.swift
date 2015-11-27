//
//  TabBarViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import SQLite

class TabBarViewController: UITabBarController {
    
    let feedNavViewController = FeedNavViewController()
    let exploreNavViewController = ExploreNavViewController()
    let activityNavViewController = ActivityNavViewController()
    let profileNavViewController = ProfileNavViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set view controllers
        viewControllers = [
            feedNavViewController,
            exploreNavViewController,
            activityNavViewController,
            profileNavViewController
        ]
        
        feedNavViewController.initNotificationIndicator()
        activityNavViewController.initNotificationIndicator()
        
        // set bar color
        tabBar.barTintColor = .Accent
        tabBar.translucent = false
        
        // set darker red as selected background color
        let numberOfItems = CGFloat(tabBar.items!.count)
        let tabBarItemSize = CGSize(width: tabBar.frame.width / numberOfItems, height: tabBar.frame.height)
        tabBar.selectionIndicatorImage = UIImage.imageBarWithColor(.whiteColor(), size: tabBarItemSize)
        
        // remove default border
        tabBar.frame.size.width = self.view.frame.width + 4
        tabBar.frame.origin.x = -2
        
        delegate = self
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        let isAllowed = !(!SessionService.isLoggedIn && (viewController == activityNavViewController || viewController == profileNavViewController))
        
        if !isAllowed {
            let alert = UIAlertController(title: "Please login first", message: "In order to see this tab you need to login or signup.\nDon't worry, it just takes 30 seconds.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Sign in", style: .Cancel, handler: { [weak self] _ in
                self?.view.window?.rootViewController = LoginViewController()
                }))
            alert.addAction(UIAlertAction(title: "Later", style: .Default, handler: { _ in return }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        return isAllowed
    }
    
}

extension TabBarViewController: UITabBarControllerDelegate {
    
}

private extension UIImage {
    
    class func imageBarWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRectMake(0, size.height - 2.5, size.width, 2.5)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}