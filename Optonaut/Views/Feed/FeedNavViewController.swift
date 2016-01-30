//
//  CollectionNavViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 01/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class FeedNavViewController: NavigationController {
    
    let viewController = OptographCollectionViewController(viewModel: FeedOptographCollectionViewModel())
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewController.navigationItem.titleView = UIImageView(image: UIImage.iconWithName(.LogoText, textColor: .whiteColor(), fontSize: 26))
        
        pushViewController(viewController, animated: false)
    }
    
    func initNotificationIndicator() {
        // TODO: simplify
//        let tabBar = tabBarController!.tabBar
//        let numberOfItems = CGFloat(tabBar.items!.count)
//        let tabBarItemSize = CGSize(width: tabBar.frame.width / numberOfItems, height: tabBar.frame.height)
//        
//        let circle = UIView()
//        circle.frame = CGRect(x: tabBarItemSize.width / 2 + 13, y: tabBarItemSize.height / 2 - 12, width: 6, height: 6)
//        circle.backgroundColor = UIColor.whiteColor()
//        circle.layer.cornerRadius = 3
//        circle.hidden = true
//        tabBar.addSubview(circle)
        
//        viewController.viewModel.newResultsAvailable.producer.startWithNext { circle.hidden = !$0 }
    }
    
}